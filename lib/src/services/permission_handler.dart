import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  final BuildContext context;

  PermissionHandler(this.context);

  checkPermissions() async {
    final permissions = await _checkRequiredPermissions();
    _handlePermissionResults(permissions);
  }

  Future<Map<Permission, PermissionStatus>> _checkRequiredPermissions() async {
    return await [
      Permission.nearbyWifiDevices,
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
    ].request();
  }

  void _handlePermissionResults(Map<Permission, PermissionStatus> statuses) {
    if (statuses[Permission.location]?.isDenied ?? true) {
      _showPermissionDeniedAlert('Location');
    }
    if (statuses[Permission.bluetooth]?.isDenied ?? true) {
      _showPermissionDeniedAlert('Bluetooth');
    }
    // ... handle other permissions
  }

  void _showPermissionDeniedAlert(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Denied'),
        content: Text('$permissionType permissions are required...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
