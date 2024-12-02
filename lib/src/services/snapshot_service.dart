import 'dart:convert';
import 'package:rocket_gps/src/models/gps_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rocket_snapshot.dart';

class SnapshotService {
  static const String _key = 'last_rocket_snapshot';

  Future<void> saveSnapshot(RocketSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  Future<RocketSnapshot?> getLastSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data == null) return null;

      final json = jsonDecode(data);
      return RocketSnapshot.fromJson(json);
    } catch (e) {
      print('Error loading snapshot: $e');
      return null;
    }
  }

  Future<void> clearSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  //to json
  Map<String, dynamic>? toJson(RocketSnapshot snapshot) {
    return {
      'latitude': snapshot.latitude,
      'longitude': snapshot.longitude,
      'altitude': snapshot.altitude,
      'timestamp': snapshot.timestamp.toIso8601String(),
    };
  }
}
