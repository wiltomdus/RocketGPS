import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rocket_snapshot.dart';

class SnapshotService {
  static const String _key = 'last_rocket_snapshot';

  Future<void> saveSnapshot(RocketSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  Future<RocketSnapshot?> getLastSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;

    try {
      return RocketSnapshot.fromJson(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
