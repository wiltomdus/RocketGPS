import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:rocket_gps/src/models/gps_data.dart';
import 'package:rocket_gps/src/utils/nmea_parser.dart';

class BluetoothConnectionException implements Exception {
  final String message;
  BluetoothConnectionException(this.message);
  @override
  String toString() => 'BluetoothConnectionException: $message';
}

class BluetoothService {
  final BluetoothClassic _bluetoothPlugin;
  final String defaultDeviceName;
  final _gpsDataController = StreamController<GPSData>.broadcast();
  List<int> _buffer = [];
  StreamSubscription? _dataSubscription;
  final _nmeaParser = NMEAParser();

  BluetoothService(this._bluetoothPlugin, {this.defaultDeviceName = 'BT04-A'});

  // Connection Methods
  Future<void> connect() async {
    try {
      var devices = await getPairedDevices();
      var targetDevice = devices.firstWhere(
        (device) => device.name == defaultDeviceName,
        orElse: () => throw BluetoothConnectionException('Device not found'),
      );

      await _bluetoothPlugin.connect(targetDevice.address, "00001101-0000-1000-8000-00805f9b34fb");
      if (_dataSubscription == null) _setupDataListener();
    } catch (e) {
      throw BluetoothConnectionException('Connection failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _bluetoothPlugin.disconnect();
    _buffer = [];
  }

  Future<List<Device>> getPairedDevices() async {
    return await _bluetoothPlugin.getPairedDevices();
  }

  // Data Handling Methods
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

      final gpsData = _nmeaParser.parseNMEASentence(sentence);
      if (gpsData != null) {
        _gpsDataController.add(gpsData);
      }

      bufferString = bufferString.substring(sentenceEnd + 1);
      sentenceEnd = bufferString.indexOf('\n');
    }

    _buffer = bufferString.codeUnits;
  }

  // Stream Accessor
  Stream<GPSData> get gpsStream => _gpsDataController.stream;

  void dispose() {
    _dataSubscription?.cancel();
    _gpsDataController.close();
  }
}
