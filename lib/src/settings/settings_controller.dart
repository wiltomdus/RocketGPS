import 'package:flutter/material.dart';
import 'dart:async';

import 'package:gps_link/src/settings/settings_service.dart';

class SettingsController with ChangeNotifier {
  final SettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;

  SettingsController(this._settingsService);

  ThemeMode get themeMode => _themeMode;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.getThemeMode();
    notifyListeners();
  }

  void updateThemeMode(ThemeMode? newMode) async {
    if (newMode != null) {
      _themeMode = newMode;
      await _settingsService.updateThemeMode(newMode);
      notifyListeners();
    }
  }
}
