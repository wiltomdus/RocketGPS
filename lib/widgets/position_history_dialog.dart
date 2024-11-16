import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:gps_link/src/models/position_history.dart';

class PositionHistoryDialog extends StatelessWidget {
  final List<Position> positions;

  const PositionHistoryDialog({
    Key? key,
    required this.positions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Position History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  final position = positions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      'Lat: ${position.latitude.toStringAsFixed(6)}°, '
                      'Lon: ${position.longitude.toStringAsFixed(6)}°',
                    ),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(position.timestamp),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
