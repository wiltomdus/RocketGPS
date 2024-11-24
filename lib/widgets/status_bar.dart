import 'package:flutter/material.dart';
import 'package:rocket_gps/src/models/device_state.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';

class StatusBar extends StatelessWidget {
  final DeviceState deviceState;
  final VoidCallback onConnect;
  final bool isScanning;

  const StatusBar({
    super.key,
    required this.deviceState,
    required this.onConnect,
    this.isScanning = false,
  });

  Color _getStatusColor() {
    switch (deviceState) {
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

  Future<void> _checkPermissionsAndConnect(BuildContext context) async {
    final bluetoothPlugin = BluetoothClassic();
    final hasPermissions = await bluetoothPlugin.initPermissions();

    if (!hasPermissions) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Bluetooth permissions are required to connect to devices.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Only call onConnect if permissions granted
    if (onConnect != null) {
      onConnect!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                deviceState == DeviceState.connected
                    ? Icons.bluetooth_connected
                    : deviceState == DeviceState.error
                        ? Icons.error_outline
                        : Icons.bluetooth_disabled,
                color: Colors.white,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Status: ${deviceState.toString().split('.').last}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _getStatusColor(),
            ),
            icon: Icon(
              deviceState == DeviceState.connected ? Icons.bluetooth_disabled : Icons.bluetooth,
            ),
            label: Text(deviceState == DeviceState.connected ? 'Disconnect' : 'Connect'),
            onPressed: isScanning ? null : () => _checkPermissionsAndConnect(context),
          ),
        ],
      ),
    );
  }
}
