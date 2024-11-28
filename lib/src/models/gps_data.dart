class GPSData {
  double latitude;
  double longitude;
  double altitude;
  final DateTime timestamp;

  GPSData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
  });
}
