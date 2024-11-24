import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:rocket_gps/src/models/gps_data.dart';

class BluetoothService {
  final BluetoothClassic _bluetoothPlugin;
  final _gpsDataController = StreamController<GPSData>.broadcast();
  List<int> _buffer = [];
  StreamSubscription? _dataSubscription;

  BluetoothService(this._bluetoothPlugin) {
    _setupDataListener();
  }

  void _setupDataListener() {
    _dataSubscription = _bluetoothPlugin.onDeviceDataReceived().listen((data) {
      _buffer = [..._buffer, ...data];
      _parseNMEAData();
    });
  }

  void _parseNMEAData() {
    String bufferString = String.fromCharCodes(_buffer);
    int sentenceEnd = bufferString.indexOf('\n');

    while (sentenceEnd != -1) {
      String sentence = bufferString.substring(0, sentenceEnd).trim();
      if (sentence.startsWith('\$GPGGA')) {
        _processGPGGASentence(sentence);
      }

      bufferString = bufferString.substring(sentenceEnd + 1);
      sentenceEnd = bufferString.indexOf('\n');
    }

    _buffer = bufferString.codeUnits;
  }

  void _processGPGGASentence(String sentence) {
    List<String> parts = sentence.split(',');
    if (parts.length >= 10) {
      try {
        double? latitude = _parseLatitude(parts[2], parts[3]);
        double? longitude = _parseLongitude(parts[4], parts[5]);
        double? altitude = double.tryParse(parts[9]);

        if (latitude != null && longitude != null && altitude != null) {
          _gpsDataController.add(GPSData(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            timestamp: DateTime.now(),
          ));
        }
      } catch (e) {
        print('Error parsing NMEA data: $e');
      }
    }
  }

  double? _parseLatitude(String value, String direction) {
    if (value.isEmpty) return null;
    double degrees = double.parse(value.substring(0, 2));
    double minutes = double.parse(value.substring(2));
    double latitude = degrees + (minutes / 60.0);
    return direction == 'S' ? -latitude : latitude;
  }

  double? _parseLongitude(String value, String direction) {
    if (value.isEmpty) return null;
    double degrees = double.parse(value.substring(0, 3));
    double minutes = double.parse(value.substring(3));
    double longitude = degrees + (minutes / 60.0);
    return direction == 'W' ? -longitude : longitude;
  }

  Future<List<Device>> getPairedDevices() async {
    return await _bluetoothPlugin.getPairedDevices();
  }

  Future<void> connect(String address) async {
    await _bluetoothPlugin.connect(address, "00001101-0000-1000-8000-00805f9b34fb");
  }

  Future<void> disconnect() async {
    await _bluetoothPlugin.disconnect();
    await _dataSubscription?.cancel();
    _buffer = [];
  }

  Stream<GPSData> get gpsStream => _gpsDataController.stream;

  void dispose() {
    _dataSubscription?.cancel();
    _gpsDataController.close();
  }
}
