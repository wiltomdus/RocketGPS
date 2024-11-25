import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rocket_gps/app_theme.dart';

class GPSDataCard extends StatelessWidget {
  final String title;
  final Position? position;
  final VoidCallback? onHistoryTap;
  final bool showDMS;
  final VoidCallback onFormatToggle;

  const GPSDataCard({
    super.key,
    required this.title,
    this.position,
    this.onHistoryTap,
    required this.showDMS,
    required this.onFormatToggle,
  });

  String _formatCoordinate(double coordinate, bool isLatitude) {
    if (showDMS) {
      var direction = isLatitude ? (coordinate >= 0 ? 'N' : 'S') : (coordinate >= 0 ? 'E' : 'W');
      coordinate = coordinate.abs();
      int degrees = coordinate.floor();
      double minutesDecimal = (coordinate - degrees) * 60;
      int minutes = minutesDecimal.floor();
      double seconds = (minutesDecimal - minutes) * 60;
      return '$degrees° $minutes\' ${seconds.toStringAsFixed(2)}" $direction';
    } else {
      return "${coordinate.toStringAsFixed(6)}°";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2), // Add spacing between title and button
                SizedBox(
                  width: 48, // Fixed width for consistency
                  child: IconButton(
                    icon: Icon(showDMS ? Icons.format_list_numbered : Icons.rotate_right),
                    onPressed: onFormatToggle,
                    tooltip: showDMS ? 'Show Decimal' : 'Show DMS',
                    padding: EdgeInsets.zero, // Reduce padding
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (position != null) ...[
              _buildGPSItem(Icons.location_on, "Latitude", _formatCoordinate(position!.latitude, true)),
              _buildGPSItem(Icons.location_on, "Longitude", _formatCoordinate(position!.longitude, false)),
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
            Icon(icon, color: AppTheme.accent, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
