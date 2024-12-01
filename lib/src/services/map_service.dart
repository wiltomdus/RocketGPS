import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter/material.dart';
import 'package:rocket_gps/src/models/gps_data.dart';

class MapService {
  final BuildContext context;

  MapService({required this.context});

  Future<void> openMapView({
    required Position? phonePosition,
    required GPSData? rocketPosition,
  }) async {
    // Validate positions
    if (!_arePositionsValid(phonePosition, rocketPosition)) {
      _showSnackBar('Waiting for GPS positions...');
      return;
    }

    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (availableMaps.isEmpty) {
        _showSnackBar('No map apps installed');
        return;
      }

      // Prefer Google Maps
      final selectedMap = availableMaps.firstWhere(
        (map) => map.mapType == MapType.google,
        orElse: () => availableMaps.first,
      );

      await selectedMap.showDirections(
        origin: Coords(
          phonePosition!.latitude,
          phonePosition.longitude,
        ),
        destination: Coords(
          rocketPosition!.latitude,
          rocketPosition.longitude,
        ),
        directionsMode: DirectionsMode.walking,
      );
    } catch (e) {
      debugPrint('Map launch error: $e');
      _showSnackBar('Error opening map: $e');
    }
  }

  bool _arePositionsValid(Position? phonePosition, GPSData? rocketPosition) {
    return phonePosition != null && rocketPosition?.latitude != null && rocketPosition?.longitude != null;
  }

  void _showSnackBar(String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
