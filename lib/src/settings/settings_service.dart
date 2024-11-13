import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyThemeMode = 'themeMode';
  static const String _keySelectedBluetoothDevice = 'selectedBluetoothDevice';
  static const String _keyIsDebugging = 'isDebugging';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> updateSelectedBluetoothDevice(String device) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_keySelectedBluetoothDevice, device);
  }

  Future<String?> getSelectedBluetoothDevice() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(_keySelectedBluetoothDevice);
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setInt(_keyThemeMode, themeMode.index);
  }

  Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await _prefs;
    int? themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.system; // Default to system theme if not set
  }

  Future<void> updateIsDebugging(bool isDebugging) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool(_keyIsDebugging, isDebugging);
  }

  Future<bool> getIsDebugging() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getBool(_keyIsDebugging) ?? true;
  }
}
