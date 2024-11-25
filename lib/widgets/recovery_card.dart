import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rocket_gps/app_theme.dart';
import 'package:rocket_gps/src/models/gps_data_item.dart';
import 'package:flutter_compass/flutter_compass.dart';

class RecoveryCard extends StatelessWidget {
  final String title;
  final List<GPSDataItem> items;
  final double? bearing;

  const RecoveryCard({
    super.key,
    required this.title,
    required this.items,
    required this.bearing,
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
                color: AppTheme.accent,
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: item.onTap,
                            child: Row(
                              children: [
                                Icon(item.icon, color: AppTheme.accent, size: 24),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      item.value,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Rocket Bearing',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (bearing != null)
                              Transform.rotate(
                                angle: bearing! * pi / 180,
                                child: const Icon(
                                  Icons.navigation,
                                  color: AppTheme.accent,
                                  size: 48,
                                ),
                              )
                            else
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 48,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (bearing != null)
                        Text(
                          '${bearing?.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Compass',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accent,
                            width: 2,
                          ),
                        ),
                        child: StreamBuilder<CompassEvent>(
                          stream: FlutterCompass.events,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 48,
                              );
                            }

                            double? direction = snapshot.data!.heading;

                            return Transform.rotate(
                              angle: (direction ?? 0) * (pi / 180) * -1,
                              child: const Icon(
                                Icons.navigation,
                                color: AppTheme.accent,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<CompassEvent>(
                        stream: FlutterCompass.events,
                        builder: (context, snapshot) {
                          double? direction = snapshot.data?.heading;
                          return Text(
                            direction != null ? '${direction.toStringAsFixed(0)}°' : '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
