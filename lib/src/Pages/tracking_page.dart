import 'dart:async';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rocket_gps/app_theme.dart';
import 'package:rocket_gps/src/models/device_state.dart';
import 'package:rocket_gps/src/models/gps_data.dart';
import 'package:rocket_gps/src/models/gps_data_item.dart';
import 'package:rocket_gps/src/models/position_history.dart';
import 'package:rocket_gps/src/services/bluetooth_service.dart';
import 'package:rocket_gps/src/services/gps_service.dart';
import 'package:rocket_gps/src/services/map_service.dart';
import 'package:rocket_gps/src/services/permission_handler.dart';
import 'package:rocket_gps/src/utils/kml_exporter.dart';
import 'package:rocket_gps/widgets/gps_data_card.dart';
import 'package:rocket_gps/widgets/recovery_card.dart';
import 'package:rocket_gps/widgets/status_bar.dart';
import 'package:intl/intl.dart';
import '../models/rocket_snapshot.dart';
import '../services/snapshot_service.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();

  static const routeName = '/geolocation';
}

class _TrackingPageState extends State<TrackingPage> {
  static const _gpsUpdateInterval = Duration(seconds: 1);
  static const _historyUpdateInterval = Duration(milliseconds: 500);
  static const _defaultBtDeviceName = 'BT04-A';

  late final PermissionHandler _permissionHandler;
  late final MapService _mapService;

  final BluetoothService _bluetoothService =
      BluetoothService(BluetoothClassic(), defaultDeviceName: _defaultBtDeviceName);
  final GPSService _gpsService;
  final PositionHistory _positionHistory = PositionHistory();
  final SnapshotService _snapshotService = SnapshotService();

  Position? _phonePosition;
  GPSData? _rocketPosition;
  bool _showDMS = false;
  DeviceState _deviceState = DeviceState.disconnected;
  bool _isScanning = false;
  Timer? _gpsTimer;
  Timer? _historyTimer;
  StreamSubscription? _dataSubscription;

  DateTime? _lastGPSUpdate;
  bool _isSnapshotData = false;

  _TrackingPageState() : _gpsService = GPSService();

  @override
  void initState() {
    super.initState();
    _permissionHandler = PermissionHandler(context);
    _permissionHandler.checkPermissions();
    _mapService = MapService(context: context);
    //_loadLastSnapshot();
    _setupTimers();
  }

  Future<void> _loadLastSnapshot() async {
    final snapshot = await _snapshotService.getLastSnapshot();
    if (snapshot != null) {
      setState(() {
        // Update GPS service with last known position
        _gpsService.updateRocketPosition(
          snapshot.latitude,
          snapshot.longitude,
          snapshot.altitude,
        );
        _rocketPosition = _gpsService.getGPSData();
        _isSnapshotData = true;
      });
    }
  }

  Future<void> _saveSnapshot() async {
    if (_rocketPosition?.latitude != null && _rocketPosition?.longitude != null && _rocketPosition?.altitude != null) {
      final snapshot = RocketSnapshot(
        latitude: _rocketPosition!.latitude,
        longitude: _rocketPosition!.longitude,
        altitude: _rocketPosition!.altitude,
        verticalVelocity: _gpsService.verticalVelocity,
        timestamp: DateTime.now(),
      );

      await _snapshotService.saveSnapshot(snapshot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rocket position snapshot saved')),
        );
      }
    }
  }

  Future<void> _clearSnapshot() async {
    await _snapshotService.clearSnapshot();
    _rocketPosition = null;
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot cleared')),
      );
    }
    _isSnapshotData = false;
    _gpsService.clearData();
  }

  void _setupTimers() {
    _gpsTimer = Timer.periodic(
      _gpsUpdateInterval,
      (_) => _updatePhoneGPS(),
    );
    _setupHistoryTimer();
  }

  void _setupHistoryTimer() {
    _historyTimer = Timer.periodic(_historyUpdateInterval, (timer) {
      if (_deviceState == DeviceState.connected &&
          _rocketPosition?.latitude != null &&
          _rocketPosition?.longitude != null &&
          _rocketPosition?.altitude != null) {
        setState(() {
          _positionHistory.add(
            Position(
              latitude: _rocketPosition!.latitude,
              longitude: _rocketPosition!.longitude,
              altitude: _rocketPosition!.altitude,
              altitudeAccuracy: 0,
              accuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
              timestamp: DateTime.now(),
            ),
          );
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
        await _bluetoothService.connect();
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
    _isSnapshotData = false;
    _dataSubscription = _bluetoothService.gpsStream.listen(
      (gpsData) {
        setState(() {
          _lastGPSUpdate = DateTime.now();
          _gpsService.updateRocketPosition(gpsData.latitude, gpsData.longitude, gpsData.altitude);
          _rocketPosition = _gpsService.getGPSData();
        });
      },
      onError: (error) {
        debugPrint('Data stream error: $error');
        setState(() => _deviceState = DeviceState.error);
      },
    );
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
                    final position = _positionHistory.history[index];
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

  Future<void> _showMapAlert() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Map'),
        content: const Text('Open map view to see rocket location and trajectory'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Map'),
          ),
        ],
      ),
    );
    if (result == true) _mapService.openMapView(phonePosition: _phonePosition, rocketPosition: _rocketPosition);
  }

  Future<void> _showExportAlert() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export KML'),
        content: const Text('Export position history to KML file'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export KML'),
          ),
        ],
      ),
    );
    if (result == true) {
      final filePath = await KMLExporter.exportPositions(_positionHistory.history);
      if (filePath == 'no positions to export') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No positions to export')),
          );
        }
      } else if (filePath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to: $filePath')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to export KML file')),
          );
        }
      }
    }
  }

  Future<void> _showSaveSnapshotAlert() async {
    final hasRocketPosition = _rocketPosition != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Position'),
        content: hasRocketPosition
            ? const Text('Save current rocket position for later use?')
            : const Text('No rocket position data available to save.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hasRocketPosition ? () => Navigator.pop(context, true) : null,
            style: TextButton.styleFrom(
              foregroundColor: hasRocketPosition ? null : Colors.grey,
            ),
            child: const Text('Save Snapshot'),
          ),
        ],
      ),
    );

    if (result == true && hasRocketPosition) {
      await _saveSnapshot();
    }
  }

  Future<void> _showLoadSnapshotAlert() async {
    RocketSnapshot? snapshot = await _snapshotService.getLastSnapshot();
    final bool hasSnapshot = snapshot != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Last Position'),
        content: hasSnapshot
            ? Text(
                'Load last saved rocket position?\n\n'
                'Latitude: ${snapshot.latitude.toStringAsFixed(6)}\n'
                'Longitude: ${snapshot.longitude.toStringAsFixed(6)}\n'
                'Altitude: ${snapshot.altitude.toStringAsFixed(1)} m\n'
                'Timestamp: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(snapshot.timestamp)}',
              )
            : const Text('No saved rocket position available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hasSnapshot ? () => Navigator.pop(context, true) : null,
            style: TextButton.styleFrom(
              foregroundColor: hasSnapshot ? null : Colors.grey,
            ), // Disabled when no snapshot
            child: const Text('Load Snapshot'),
          ),
        ],
      ),
    );

    if (result == true && hasSnapshot) {
      _loadLastSnapshot();
    }
  }

  Future<void> _showClearSnapshotAlert() async {
    final hasSnapshot = await _snapshotService.getLastSnapshot() != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Saved Position'),
        content: hasSnapshot
            ? const Text('Remove saved rocket position data?')
            : const Text('No saved rocket position available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hasSnapshot ? () => Navigator.pop(context, true) : null,
            style: TextButton.styleFrom(
              foregroundColor: hasSnapshot ? null : Colors.grey,
            ),
            child: const Text('Clear Snapshot'),
          ),
        ],
      ),
    );

    if (result == true && hasSnapshot) {
      await _clearSnapshot();
    }
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
                      position: _rocketPosition?.latitude != null
                          ? Position(
                              latitude: _rocketPosition!.latitude,
                              longitude: _rocketPosition!.longitude,
                              altitude: _rocketPosition!.altitude,
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
                      isSnapshot: _isSnapshotData,
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
                    label: "Vertical Velocity",
                    value: _gpsService.verticalVelocity != null
                        ? "${_gpsService.verticalVelocity?.toStringAsFixed(1)} ft/s"
                        : "N/A",
                  ),
                  GPSDataItem(
                    icon: Icons.straighten,
                    label: "Distance to Rocket",
                    value:
                        "${_gpsService.hasValidPositions ? _gpsService.calculateDistance().toStringAsFixed(1) : 'N/A'} m",
                  ),
                  GPSDataItem(
                    icon: Icons.navigation,
                    label: "Bearing to Rocket",
                    value:
                        "${_gpsService.hasValidPositions ? _gpsService.calculateBearing()?.toStringAsFixed(0) : 'N/A'}°",
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
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _showMapAlert,
                    icon: const Icon(Icons.map),
                    color: AppTheme.accent,
                    tooltip: 'View Map',
                  ),
                  IconButton(
                    onPressed: _showExportAlert,
                    icon: const Icon(Icons.upload_file),
                    color: AppTheme.accent,
                    tooltip: 'Export KML',
                  ),
                  IconButton(
                    onPressed: _showSaveSnapshotAlert,
                    icon: const Icon(Icons.save),
                    color: AppTheme.accent,
                    tooltip: 'Save Position',
                  ),
                  IconButton(
                      onPressed: _showLoadSnapshotAlert,
                      icon: const Icon(Icons.restore),
                      color: AppTheme.accent,
                      tooltip: 'Load Snapshot'),
                  IconButton(
                    onPressed: _showClearSnapshotAlert,
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    tooltip: 'Clear Saved',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            StatusBar(
              deviceState: _deviceState,
              onConnect: _handleConnection,
              isScanning: _isScanning,
            ),
          ],
        ),
      ],
    );
  }
}
