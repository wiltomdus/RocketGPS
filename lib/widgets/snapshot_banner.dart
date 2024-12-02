import 'package:flutter/material.dart';

class SnapshotBanner extends StatelessWidget {
  const SnapshotBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Banner(
      message: 'SNAPSHOT',
      location: BannerLocation.bottomEnd,
      color: Colors.orange,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
