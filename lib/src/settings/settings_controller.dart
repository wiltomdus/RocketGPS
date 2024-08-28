import 'package:flutter/material.dart';
import 'settings_service.dart';

class SettingsController with ChangeNotifier {
  final SettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;
  String? _selectedBluetoothDevice;

  SettingsController(this._settingsService);

  ThemeMode get themeMode => _themeMode;
  String? get selectedBluetoothDevice => _selectedBluetoothDevice;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.getThemeMode();
    _selectedBluetoothDevice = await _settingsService.getSelectedBluetoothDevice();
    notifyListeners();
  }

  void updateThemeMode(ThemeMode? newMode) async {
    if (newMode != null) {
      _themeMode = newMode;
      await _settingsService.updateThemeMode(newMode);
      notifyListeners();
    }
  }

  Future<List<String>> getPairedBluetoothDevices() async {
    return _settingsService.getPairedBluetoothDevices();
  }

  void updateSelectedBluetoothDevice(String device) async {
    _selectedBluetoothDevice = device;
    await _settingsService.updateSelectedBluetoothDevice(device);
    notifyListeners();
  }

  void openBluetoothSettings() {
    // Android intent to open Bluetooth settings
  }
}
