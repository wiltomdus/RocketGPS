import 'package:flutter/material.dart';
import 'package:gps_link/widgets/mock_location_widget.dart';
import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;
  static const routeName = '/settings';

  const SettingsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Selector
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: const Text('Select app theme'),
            trailing: DropdownButton<ThemeMode>(
              value: controller.themeMode,
              onChanged: controller.updateThemeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
          ),
          const Divider(),

          // Bluetooth Section
          const ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Bluetooth Settings'),
          ),
          // Paired Devices Dropdown
          FutureBuilder<List<String>>(
            future: controller.getPairedBluetoothDevices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No paired Bluetooth devices found.');
              } else {
                return DropdownButton<String>(
                  value: controller.selectedBluetoothDevice,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateSelectedBluetoothDevice(newValue);
                    }
                  },
                  items: snapshot.data!.map<DropdownMenuItem<String>>((String device) {
                    return DropdownMenuItem<String>(
                      value: device,
                      child: Text(device),
                    );
                  }).toList(),
                  hint: const Text('Select a paired device'),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          // Bluetooth Settings Button
          ElevatedButton.icon(
            icon: const Icon(Icons.settings_bluetooth),
            label: const Text('Open Bluetooth Settings'),
            onPressed: controller.openBluetoothSettings,
          ),
          const Divider(),

          // Help Button for Mock Location Instructions
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Mock Location Setup Help'),
            trailing: ElevatedButton(
              child: const Text('Help'),
              onPressed: () => _showMockLocationInstructions(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showMockLocationInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const MockLocationInstructions(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
