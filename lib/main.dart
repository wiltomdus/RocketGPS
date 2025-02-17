import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

import 'package:bluetooth_classic/bluetooth_classic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Run the app and pass in the SettingsController. The app listens to the
    // SettingsController for changes, then passes it further down to the
    // SettingsView.
    runApp(MyApp(settingsController: settingsController));
  });
}

void initBluetoothPermissions(BluetoothClassic bluetoothPlugin) async {
  await bluetoothPlugin.initPermissions();
}
