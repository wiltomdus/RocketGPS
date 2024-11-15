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
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

enum DeviceState { disconnected, connecting, connected, error }

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

  final List<Map<String, dynamic>> _positionHistory = [];
  Timer? _historyTimer;

  @override
  void initState() {
    super.initState();

    // Start the timer to refresh phone GPS data every 1s
    _gpsTimer = Timer.periodic(const Duration(seconds: 1), _refreshPhoneGPS);

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

    _historyTimer = Timer.periodic(const Duration(seconds: 2), _recordPosition);
  }

  @override
  void dispose() {
    // Cancel the timer when the page is disposed
    _gpsTimer?.cancel();
    _historyTimer?.cancel();
    super.dispose();
  }

  // Function to parse NMEA data and extract latitude, longitude, and altitude
  void _parseNMEAData(Uint8List event) {
    String nmeaString = String.fromCharCodes(event);

    // Look for a GPGGA sentence which contains the location information
    if (nmeaString.startsWith("\$GPGGA")) {
      List<String> nmeaParts = nmeaString.split(',');

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
      });
    } catch (e) {
      print("Error refreshing phone GPS: $e");
    }
  }

  bool _isValidLatitude(double lat) => lat >= -90 && lat <= 90;
  bool _isValidLongitude(double lon) => lon >= -180 && lon <= 180;

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
        try {
          await _bluetoothClassicPlugin.connect(_devices.first.address, "00001101-0000-1000-8000-00805f9b34fb");
        } catch (e) {
          setState(() {
            _deviceStatus = _deviceStateToInt(DeviceState.error);
          });
          print("Connection failed: $e");
        }
      }
    }
  }

  // Add these conversion methods
  DeviceState _intToDeviceState(int status) {
    switch (status) {
      case 0:
        return DeviceState.disconnected;
      case 1:
        return DeviceState.connecting;
      case 2:
        return DeviceState.connected;
      case 3:
        return DeviceState.error;
      default:
        return DeviceState.disconnected;
    }
  }

  int _deviceStateToInt(DeviceState state) {
    switch (state) {
      case DeviceState.disconnected:
        return 0;
      case DeviceState.connecting:
        return 1;
      case DeviceState.connected:
        return 2;
      case DeviceState.error:
        return 3;
    }
  }

  // Update the color method
  Color _getStatusColor() {
    final state = _intToDeviceState(_deviceStatus);
    switch (state) {
      case DeviceState.connected:
        return Colors.green;
      case DeviceState.connecting:
        return Colors.orange;
      case DeviceState.error:
        return Colors.red;
      case DeviceState.disconnected:
        return Colors.grey;
    }
  }

  // Update the text method
  String _getStatusText() {
    final state = _intToDeviceState(_deviceStatus);
    switch (state) {
      case DeviceState.connected:
        return 'Disconnect';
      case DeviceState.connecting:
        return 'Connecting...';
      case DeviceState.error:
        return 'Retry Connection';
      case DeviceState.disconnected:
        return 'Connect';
    }
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

  double _calculateDistance() {
    if (_phonePosition == null || _latitude == null || _longitude == null) {
      return 0.0;
    }

    const R = 6371e3; // Earth's radius in meters
    final lat1 = _phonePosition!.latitude * pi / 180;
    final lat2 = _latitude! * pi / 180;
    final deltaLat = (_latitude! - _phonePosition!.latitude) * pi / 180;
    final deltaLon = (_longitude! - _phonePosition!.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _calculateBearingValue() {
    if (_phonePosition == null || _latitude == null || _longitude == null) {
      return 0.0;
    }

    final lat1 = _phonePosition!.latitude * pi / 180;
    final lat2 = _latitude! * pi / 180;
    final lon1 = _phonePosition!.longitude * pi / 180;
    final lon2 = _longitude! * pi / 180;

    final y = sin(lon2 - lon1) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    final bearing = atan2(y, x);

    return (bearing * 180 / pi + 360) % 360;
  }

  Future<void> _openMapView() async {
    if (_phonePosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for phone GPS position...')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for rocket GPS position...')),
      );
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&origin=${_phonePosition!.latitude},${_phonePosition!.longitude}'
        '&destination=${_latitude},${_longitude}'
        '&travelmode=walking'
        '&markers=color:blue|label:P|${_phonePosition!.latitude},${_phonePosition!.longitude}'
        '&markers=color:red|label:R|${_latitude},${_longitude}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map')),
        );
      }
    } catch (e) {
      debugPrint('Error opening map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening map')),
      );
    }
  }

  void _recordPosition(Timer timer) {
    if (_latitude != null && _longitude != null) {
      setState(() {
        _positionHistory.insert(0, {
          'latitude': _latitude,
          'longitude': _longitude,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  void _showPositionHistory() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Position History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _positionHistory.length,
                  itemBuilder: (context, index) {
                    final position = _positionHistory[index];
                    final timestamp = position['timestamp'] as DateTime;
                    return ListTile(
                      dense: true,
                      title: Text(
                        'Lat: ${position['latitude']?.toStringAsFixed(6)}°, '
                        'Lon: ${position['longitude']?.toStringAsFixed(6)}°',
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _latitude != null && _longitude != null && _altitude != null
                          ? GPSDataCard(
                              title: "Rocket GPS",
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
                                  value: "${(_altitude! * 3.28084).toStringAsFixed(2)} ft",
                                ),
                              ],
                            )
                          : const Card(
                              elevation: 4,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Waiting for rocket GPS data...",
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _phonePosition != null
                          ? GPSDataCard(
                              title: "Phone GPS",
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
                                  icon: Icons.height,
                                  label: "Altitude",
                                  value: "${(_phonePosition!.altitude * 3.28084).toStringAsFixed(2)} ft",
                                ),
                              ],
                            )
                          : const Card(
                              elevation: 4,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "Waiting for phone GPS data...",
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              GPSDataCard(title: 'Recovery', items: [
                GPSDataItem(
                  icon: Icons.speed,
                  label: "Vertical Speed",
                  value: "${_data.isNotEmpty ? (_data.last * 3.28084).toStringAsFixed(2) : 'N/A'} ft/s",
                ),
                GPSDataItem(
                  icon: Icons.straighten,
                  label: "Distance to Rocket",
                  value:
                      "${_phonePosition != null && _latitude != null && _longitude != null ? _calculateDistance().toStringAsFixed(2) : 'N/A'} m",
                ),
                GPSDataItem(
                  icon: Icons.navigation,
                  label: "Bearing to Rocket",
                  value:
                      "${_phonePosition != null && _latitude != null && _longitude != null ? _calculateBearingValue().toStringAsFixed(2) : 'N/A'}°",
                ),
                GPSDataItem(
                  icon: Icons.gps_fixed,
                  label: "Last Positions",
                  value: "${_positionHistory.length} recorded",
                  onTap: _showPositionHistory,
                ),
              ]),

              SizedBox(
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
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMapView,
              icon: const Icon(Icons.map),
              label: const Text('View Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _getStatusColor(),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status indicator
                Row(
                  children: [
                    Icon(
                      _intToDeviceState(_deviceStatus) == DeviceState.connected
                          ? Icons.bluetooth_connected
                          : _intToDeviceState(_deviceStatus) == DeviceState.error
                              ? Icons.error_outline
                              : Icons.bluetooth_disabled,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Status: ${_intToDeviceState(_deviceStatus).toString().split('.').last}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Connection button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _getStatusColor(),
                  ),
                  icon: Icon(
                    _intToDeviceState(_deviceStatus) == DeviceState.connected
                        ? Icons.bluetooth_disabled
                        : Icons.bluetooth,
                  ),
                  label: Text(_getStatusText()),
                  onPressed: _scanning ? null : _toggleConnection,
                ),
              ],
            ),
            // Error message
            if (_intToDeviceState(_deviceStatus) == DeviceState.error)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Connection failed. Please check device and try again.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
