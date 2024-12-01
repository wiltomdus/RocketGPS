import 'package:flutter/material.dart';
import 'package:rocket_gps/src/models/gps_data.dart';

class NMEAParser {
  static const String GPGGA_IDENTIFIER = '\$GPGGA';

  GPSData? parseNMEASentence(String sentence) {
    if (!sentence.startsWith(GPGGA_IDENTIFIER)) return null;

    List<String> parts = sentence.split(',');
    if (parts.length < 10) return null;

    try {
      double? latitude = _parseLatitude(parts[2], parts[3]);
      double? longitude = _parseLongitude(parts[4], parts[5]);
      double? altitude = double.tryParse(parts[9]);

      if (latitude != null && longitude != null && altitude != null) {
        return GPSData(
          latitude: latitude,
          longitude: longitude,
          altitude: altitude,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('NMEA parsing error: $e');
    }
    return null;
  }

  double? _parseLatitude(String value, String direction) {
    if (value.isEmpty) return null;
    double degrees = double.parse(value.substring(0, 2));
    double minutes = double.parse(value.substring(2));
    double latitude = degrees + (minutes / 60.0);
    return direction == 'S' ? -latitude : latitude;
  }

  double? _parseLongitude(String value, String direction) {
    if (value.isEmpty) return null;
    double degrees = double.parse(value.substring(0, 3));
    double minutes = double.parse(value.substring(3));
    double longitude = degrees + (minutes / 60.0);
    return direction == 'W' ? -longitude : longitude;
  }
}
