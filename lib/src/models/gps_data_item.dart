import 'package:flutter/material.dart';

class GPSDataItem {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  GPSDataItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
}
