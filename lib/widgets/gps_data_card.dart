import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_link/src/models/gps_data_item.dart';

class GPSDataCard extends StatelessWidget {
  final String title;
  final Position? position;
  final VoidCallback? onHistoryTap;

  const GPSDataCard({
    super.key,
    required this.title,
    this.position,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            if (position != null) ...[
              _buildGPSItem(Icons.location_on, "Latitude", "${position!.latitude.toStringAsFixed(6)}°"),
              _buildGPSItem(Icons.location_on, "Longitude", "${position!.longitude.toStringAsFixed(6)}°"),
              _buildGPSItem(Icons.height, "Altitude", "${position!.altitude.toStringAsFixed(1)} m"),
              if (onHistoryTap != null) _buildGPSItem(Icons.history, "History", "View", onTap: onHistoryTap),
            ] else
              const Text("Waiting for data...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSItem(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple[700], size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
