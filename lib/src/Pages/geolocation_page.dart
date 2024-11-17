import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_link/src/models/device_state.dart';
import 'package:gps_link/src/models/gps_data_item.dart';
import 'package:gps_link/src/services/bluetooth_service.dart';
import 'package:gps_link/src/services/gps_service.dart';
import 'package:gps_link/src/utils/kml_exporter.dart';
import 'package:gps_link/widgets/gps_data_card.dart';
import 'package:gps_link/widgets/recovery_card.dart';
import 'package:gps_link/widgets/status_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({super.key});

  @override
  State<GeolocationPage> createState() => _GeolocationPageState();

  static const routeName = '/geolocation';
}

class _GeolocationPageState extends State<GeolocationPage> {
  final BluetoothService _bluetoothService;
  final GPSService _gpsService;
  final List<Position> _positionHistory = [];

  Position? _phonePosition;
  double? _latitude;

  double? _longitude;
  double? _altitude;
  bool _showDMS = false;
  DeviceState _deviceState = DeviceState.disconnected;
  bool _isScanning = false;
  Timer? _gpsTimer;
  Timer? _historyTimer;
  StreamSubscription? _dataSubscription;

  DateTime? _lastGPSUpdate;

  _GeolocationPageState()
      : _bluetoothService = BluetoothService(BluetoothClassic()),
        _gpsService = GPSService();

  @override
  void initState() {
    super.initState();
    _setupTimers();
  }

  void _setupTimers() {
    _gpsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updatePhoneGPS(),
    );
    _setupHistoryTimer();
  }

  void _setupHistoryTimer() {
    _historyTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_deviceState == DeviceState.connected && _latitude != null && _longitude != null && _altitude != null) {
        setState(() {
          _positionHistory.insert(
              0,
              Position(
                latitude: _latitude!,
                longitude: _longitude!,
                altitude: _altitude!,
                altitudeAccuracy: 0,
                accuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
                timestamp: DateTime.now(),
              ));
        });
      }
    });
  }

  void _updatePhoneGPS() async {
    try {
      Position position = await _gpsService.getCurrentPosition();
      setState(() => _phonePosition = position);
      _gpsService.updatePhonePosition(position);
    } catch (e) {
      debugPrint('Error refreshing phone GPS: $e');
    }
  }

  Future<void> _handleConnection() async {
    if (_deviceState == DeviceState.connected) {
      await _bluetoothService.disconnect();
      _dataSubscription?.cancel();
      setState(() => _deviceState = DeviceState.disconnected);
    } else {
      setState(() => _isScanning = true);
      try {
        var devices = await _bluetoothService.getPairedDevices();
        var targetDevice = devices.firstWhere(
          (device) => device.name == 'BT04-A',
          orElse: () => throw Exception('Device not found'),
        );

        await _bluetoothService.connect(targetDevice.address);
        _setupDataStream();
        setState(() => _deviceState = DeviceState.connected);
      } catch (e) {
        debugPrint('Connection error: $e');
        setState(() => _deviceState = DeviceState.error);
      } finally {
        setState(() => _isScanning = false);
      }
    }
  }

  void _setupDataStream() {
    _dataSubscription = _bluetoothService.gpsStream.listen(
      (gpsData) {
        setState(() {
          _latitude = gpsData.latitude;
          _longitude = gpsData.longitude;
          _altitude = gpsData.altitude;
          _lastGPSUpdate = DateTime.now();
          _gpsService.updateRocketPosition(gpsData.latitude, gpsData.longitude, gpsData.altitude);
        });
      },
      onError: (error) {
        debugPrint('Data stream error: $error');
        setState(() => _deviceState = DeviceState.error);
      },
    );
  }

  Future<void> _openMapView() async {
    if (_phonePosition == null || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS positions...')),
      );
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&origin=${_phonePosition!.latitude},${_phonePosition!.longitude}'
        '&destination=${_latitude},${_longitude}'
        '&travelmode=walking');

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
                    return ListTile(
                      dense: true,
                      title: Text(
                        'Lat: ${position.latitude.toStringAsFixed(6)}°, '
                        'Lon: ${position.longitude.toStringAsFixed(6)}°',
                      ),
                      subtitle: Text(
                        'Alt: ${position.altitude.toStringAsFixed(1)}m - '
                        '${DateFormat('HH:mm:ss').format(position.timestamp)}',
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
  void dispose() {
    _gpsTimer?.cancel();
    _historyTimer?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GPSDataCard(
                      title: "Rocket",
                      position: _latitude != null
                          ? Position(
                              latitude: _latitude!,
                              longitude: _longitude!,
                              altitude: _altitude!,
                              altitudeAccuracy: 0,
                              accuracy: 0,
                              heading: 0,
                              headingAccuracy: 0,
                              speed: 0,
                              speedAccuracy: 0,
                              timestamp: DateTime.now(),
                            )
                          : null,
                      onHistoryTap: _showPositionHistory,
                      showDMS: _showDMS,
                      onFormatToggle: () => setState(() => _showDMS = !_showDMS),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GPSDataCard(
                      title: "Phone",
                      position: _phonePosition,
                      showDMS: _showDMS,
                      onFormatToggle: () => setState(() => _showDMS = !_showDMS),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RecoveryCard(
                title: 'Recovery',
                bearing: _gpsService.calculateBearing(),
                items: [
                  GPSDataItem(
                    icon: Icons.speed,
                    label: "Vertical Speed",
                    value: "${_gpsService.verticalVelocity.toStringAsFixed(2)} ft/s",
                  ),
                  GPSDataItem(
                    icon: Icons.straighten,
                    label: "Distance to Rocket",
                    value:
                        "${_gpsService.hasValidPositions ? _gpsService.calculateDistance().toStringAsFixed(2) : 'N/A'} m",
                  ),
                  GPSDataItem(
                    icon: Icons.navigation,
                    label: "Bearing to Rocket",
                    value:
                        "${_gpsService.hasValidPositions ? _gpsService.calculateBearing().toStringAsFixed(2) : 'N/A'}°",
                  ),
                  GPSDataItem(
                    icon: Icons.timer,
                    label: "Last Update",
                    value:
                        _lastGPSUpdate != null ? "${DateTime.now().difference(_lastGPSUpdate!).inSeconds}s ago" : "N/A",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final filePath = await KMLExporter.exportPositions(_positionHistory);
                    if (filePath != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved to: $filePath')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to export KML file')),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Export KML'),
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
            ],
          ),
        ),
      ],
      bottomNavigationBar: StatusBar(
        deviceState: _deviceState,
        onConnect: _handleConnection,
        isScanning: _isScanning,
      ),
    );
  }
}
