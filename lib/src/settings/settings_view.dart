import 'package:flutter/material.dart';
import 'settings_controller.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';

class SettingsView extends StatefulWidget {
  final SettingsController controller;
  static const routeName = '/settings';

  const SettingsView({super.key, required this.controller});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _bluetoothClassicPlugin = BluetoothClassic();

  @override
  void initState() {
    super.initState();
  }

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
              value: widget.controller.themeMode,
              onChanged: widget.controller.updateThemeMode,
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
          TextButton(
            onPressed: () async {
              await _bluetoothClassicPlugin.initPermissions();
            },
            child: const Text("Check Permissions"),
          ),
        ],
      ),
    );
  }
}
