// geolocation_page.dart

import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:geolocator/geolocator.dart';
import 'mock_nmea_data_generator.dart';

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({super.key});

  static const routeName = '/geolocation';

  @override
  State<GeolocationPage> createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage> {
  BluetoothConnection? _connection;
  String _nmeaData = "";
  String _latitude = "";
  String _longitude = "";
  String _altitude = "";
  String _numSatellites = "";
  String _phoneLatitude = "";
  String _phoneLongitude = "";
  String _distance = "";
  double _bearing = 0.0;
  late MockNmeaDataGenerator _mockNmeaDataGenerator;

  @override
  void initState() {
    super.initState();
    _mockNmeaDataGenerator = MockNmeaDataGenerator();
    _scanAndConnect();
    _listenToMockData();
    _getPhoneLocation();
  }

  void _scanAndConnect() async {
    try {
      BluetoothDevice? selectedDevice;
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();

      for (BluetoothDevice device in devices) {
        if (device.name == 'BT-04' || device.name == 'HC-05') {
          selectedDevice = device;
          break;
        }
      }

      if (selectedDevice != null) {
        BluetoothConnection connection = await BluetoothConnection.toAddress(selectedDevice.address);
        setState(() {
          _connection = connection;
        });
        connection.input!.listen((Uint8List data) {
          String nmeaData = String.fromCharCodes(data);
          setState(() {
            _nmeaData = nmeaData;
            _parseNmeaData(nmeaData);
            _calculateDistanceAndBearing();
          });
        });
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void _listenToMockData() {
    _mockNmeaDataGenerator.nmeaStream.listen((mockData) {
      setState(() {
        _nmeaData = mockData;
        _parseNmeaData(mockData);
        _calculateDistanceAndBearing();
      });
    });
  }

  void _getPhoneLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _phoneLatitude = position.latitude.toStringAsFixed(6);
      _phoneLongitude = position.longitude.toStringAsFixed(6);
      _calculateDistanceAndBearing();
    });
  }

  void _parseNmeaData(String nmeaData) {
    if (nmeaData.startsWith('\$GPGGA')) {
      List<String> parts = nmeaData.split(',');
      if (parts.length > 9) {
        _latitude = _convertToDecimal(parts[2], parts[3]);
        _longitude = _convertToDecimal(parts[4], parts[5]);
        _altitude = parts[9] + ' ' + parts[10];
        _numSatellites = parts[7];
      }
    }
  }

  String _convertToDecimal(String value, String direction) {
    if (value.isEmpty) return "";
    double degrees = double.parse(value.substring(0, 2));
    double minutes = double.parse(value.substring(2)) / 60;
    double decimal = degrees + minutes;
    if (direction == 'S' || direction == 'W') {
      decimal *= -1;
    }
    return decimal.toStringAsFixed(6);
  }

  void _calculateDistanceAndBearing() {
    if (_latitude.isNotEmpty && _longitude.isNotEmpty && _phoneLatitude.isNotEmpty && _phoneLongitude.isNotEmpty) {
      double lat1 = double.parse(_latitude);
      double lon1 = double.parse(_longitude);
      double lat2 = double.parse(_phoneLatitude);
      double lon2 = double.parse(_phoneLongitude);

      double distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
      double bearing = _calculateBearing(lat1, lon1, lat2, lon2);

      setState(() {
        _distance = distance.toStringAsFixed(2) + ' meters';
        _bearing = bearing;
      });
    }
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = lat1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double deltaLon = (lon2 - lon1) * pi / 180;

    double y = sin(deltaLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLon);
    double bearingRad = atan2(y, x);
    double bearingDeg = (bearingRad * 180 / pi + 360) % 360;

    return bearingDeg;
  }

  @override
  void dispose() {
    _connection?.dispose();
    _mockNmeaDataGenerator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NMEA Data',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _nmeaData,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latitude',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _latitude,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Longitude',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _longitude,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.purple.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Altitude',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _altitude,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Number of Satellites',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _numSatellites,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.teal.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Latitude',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _phoneLatitude,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Longitude',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _phoneLongitude,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance to Bluetooth Device',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _distance,
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade800,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Direction to Bluetooth Device',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    Transform.rotate(
                      angle: _bearing * pi / 180,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 60.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Bearing: ${_bearing.toStringAsFixed(2)}°',
                      style: const TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
