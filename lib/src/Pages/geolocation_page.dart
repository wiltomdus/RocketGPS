import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:gps_link/src/models/gps_data_item.dart';
import 'package:gps_link/src/settings/settings_controller.dart';
import 'package:gps_link/widgets/gps_data_card.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'package:provider/provider.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';

class GeolocationPage extends StatefulWidget {
  final SettingsController settingsController;

  const GeolocationPage({super.key, required this.settingsController});
  @override
  State<GeolocationPage> createState() => _GeolocationPageState();

  static const routeName = '/geolocation';
}

class _GeolocationPageState extends State<GeolocationPage> {
  Position? _phonePosition;
  Position? _bluetoothPosition;
  double? _bearing;
  double? _distance;
  Stream<Position>? _bluetoothStream;
  StreamSubscription<Position>? _phonePositionSubscription;
  Timer? _gpsTimer; // Timer for refreshing GPS data

  String _platformVersion = 'Unknown';
  final _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  bool _scanning = false;
  int _deviceStatus = Device.disconnected;
  Uint8List _data = Uint8List(0);

  double? _latitude;
  double? _longitude;
  double? _altitude;

  @override
  void initState() {
    super.initState();

    // Start the timer to refresh phone GPS data every 10ms
    _gpsTimer = Timer.periodic(const Duration(milliseconds: 10), _refreshPhoneGPS);

    // Listen for Bluetooth status changes
    _bluetoothClassicPlugin.onDeviceStatusChanged().listen((event) {
      setState(() {
        _deviceStatus = event;
      });
    });

    // Listen for data from Bluetooth device
    _bluetoothClassicPlugin.onDeviceDataReceived().listen((event) {
      setState(() {
        _data = Uint8List.fromList([..._data, ...event]);
        _parseNMEAData(event);
      });
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the page is disposed
    _gpsTimer?.cancel();
    super.dispose();
  }

  // Function to parse NMEA data and extract latitude, longitude, and altitude
  void _parseNMEAData(Uint8List event) {
    String nmeaString = String.fromCharCodes(event);

    // Look for a GPGGA sentence which contains the location information
    if (nmeaString.startsWith("\$GPGGA")) {
      List<String> nmeaParts = nmeaString.split(',');
      print("NMEA Parts: $nmeaParts");

      if (nmeaParts.length >= 9) {
        // Extract latitude and longitude from the sentence
        String latitudeStr = nmeaParts[2];
        String longitudeStr = nmeaParts[4];
        String latitudeHemisphere = nmeaParts[3];
        String longitudeHemisphere = nmeaParts[5];
        String altitudeStr = nmeaParts[9];

        // Parse latitude, longitude, and altitude
        if (latitudeStr.isNotEmpty && longitudeStr.isNotEmpty) {
          _latitude = _parseCoordinate(latitudeStr, latitudeHemisphere);
          _longitude = _parseCoordinate(longitudeStr, longitudeHemisphere);
          _altitude = double.tryParse(altitudeStr);
        }
        print("Latitude: $_latitude, Longitude: $_longitude, Altitude: $_altitude");
      }
    }

    setState(() {});
  }

  // Function to parse coordinates
  double _parseCoordinate(String coordinate, String hemisphere) {
    double value = double.tryParse(coordinate) ?? 0;
    int degrees = (value / 100).floor();
    double minutes = value - (degrees * 100);
    double decimalCoordinate = degrees + (minutes / 60);

    // Adjust based on hemisphere
    if (hemisphere == 'S' || hemisphere == 'W') {
      decimalCoordinate = -decimalCoordinate;
    }

    return decimalCoordinate;
  }

  // Timer callback to refresh phone's GPS data
  void _refreshPhoneGPS(Timer timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _phonePosition = position;
        _updateBearingAndDistance();
      });
    } catch (e) {
      print("Error refreshing phone GPS: $e");
    }
  }

  void _updateBearingAndDistance() {
    if (_phonePosition != null && _bluetoothPosition != null) {
      final lat1 = vmath.radians(_phonePosition!.latitude);
      final lon1 = vmath.radians(_phonePosition!.longitude);
      final lat2 = vmath.radians(_bluetoothPosition!.latitude);
      final lon2 = vmath.radians(_bluetoothPosition!.longitude);

      final dLon = lon2 - lon1;
      final y = sin(dLon) * cos(lat2);
      final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
      final bearing = atan2(y, x);
      setState(() {
        _bearing = vmath.degrees(bearing);
        _distance = Geolocator.distanceBetween(
          _phonePosition!.latitude,
          _phonePosition!.longitude,
          _bluetoothPosition!.latitude,
          _bluetoothPosition!.longitude,
        );
      });
    }
  }

  Future<void> _toggleConnection() async {
    if (_deviceStatus == Device.connected) {
      await _bluetoothClassicPlugin.disconnect();
    } else {
      setState(() {
        _scanning = true;
      });
      var pairedDevices = await _bluetoothClassicPlugin.getPairedDevices();
      setState(() {
        _devices = pairedDevices.where((device) => device.name == 'BT04-A').toList();
        _scanning = false;
      });

      if (_devices.isNotEmpty) {
        await _bluetoothClassicPlugin.connect(_devices.first.address, "00001101-0000-1000-8000-00805f9b34fb");
      }
    }
  }

  Color _getStatusColor() {
    switch (_deviceStatus) {
      case Device.connected:
        return Colors.green;
      case Device.connecting:
        return Colors.orange;
      case Device.disconnected:
      default:
        return Colors.red;
    }
  }

  String _getStatusText() {
    return _deviceStatus == Device.connected ? 'Disconnect' : 'Connect';
  }

  // Add this function to calculate bearing
  double _calculateBearing() {
    if (_phonePosition == null || _latitude == null || _longitude == null) return 0;

    final lat1 = _phonePosition!.latitude * pi / 180;
    final lon1 = _phonePosition!.longitude * pi / 180;
    final lat2 = _latitude! * pi / 180;
    final lon2 = _longitude! * pi / 180;

    final y = sin(lon2 - lon1) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    final bearing = atan2(y, x);

    return (bearing * 180 / pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Bluetooth GPS Data Section
              _latitude != null && _longitude != null && _altitude != null
                  ? GPSDataCard(
                      title: "Bluetooth Device GPS Data",
                      items: [
                        GPSDataItem(
                          icon: Icons.location_on,
                          label: "Latitude",
                          value: "${_latitude!.toStringAsFixed(6)}°",
                        ),
                        GPSDataItem(
                          icon: Icons.location_on,
                          label: "Longitude",
                          value: "${_longitude!.toStringAsFixed(6)}°",
                        ),
                        GPSDataItem(
                          icon: Icons.height,
                          label: "Altitude",
                          value: "${_altitude!.toStringAsFixed(2)} meters",
                        ),
                      ],
                    )
                  : const Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Waiting for Bluetooth GPS data...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 30),

              // Add this widget between the GPS data sections
              Container(
                height: 100,
                width: 100,
                child: _phonePosition != null && _latitude != null && _longitude != null
                    ? Transform.rotate(
                        angle: _calculateBearing() * pi / 180,
                        child: const Icon(
                          Icons.arrow_upward,
                          size: 60,
                          color: Colors.blue,
                        ),
                      )
                    : const SizedBox(),
              ),

              const SizedBox(height: 20),

              // Phone GPS Data Section
              _phonePosition != null
                  ? GPSDataCard(
                      title: "Phone GPS Data",
                      items: [
                        GPSDataItem(
                          icon: Icons.location_on,
                          label: "Latitude",
                          value: "${_phonePosition!.latitude.toStringAsFixed(6)}°",
                        ),
                        GPSDataItem(
                          icon: Icons.location_on,
                          label: "Longitude",
                          value: "${_phonePosition!.longitude.toStringAsFixed(6)}°",
                        ),
                        GPSDataItem(
                          icon: Icons.speed,
                          label: "Speed",
                          value: "${(_phonePosition!.speed * 3.6).toStringAsFixed(1)} km/h",
                        ),
                        GPSDataItem(
                          icon: Icons.height,
                          label: "Altitude",
                          value: "${_phonePosition!.altitude.toStringAsFixed(1)} meters",
                        ),
                      ],
                    )
                  : const Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Waiting for phone GPS data...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: _getStatusColor(),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Existing status indicator
            Row(
              children: [
                Icon(
                  _deviceStatus == Device.connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: Colors.white,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Bluetooth Status: ${_deviceStatus == Device.connected ? "Connected" : "Disconnected"}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),

            // New connection toggle button
            ElevatedButton.icon(
              icon: Icon(
                _deviceStatus == Device.connected ? Icons.bluetooth_disabled : Icons.bluetooth,
              ),
              label: Text(_getStatusText()),
              onPressed: _scanning ? null : _toggleConnection,
            ),
          ],
        ),
      ),
    );
  }
}
