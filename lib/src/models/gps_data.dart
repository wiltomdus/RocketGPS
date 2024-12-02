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

  //from RocketSnapshot
  GPSData.fromJson(Map<String, dynamic> json)
      : latitude = json['latitude'],
        longitude = json['longitude'],
        altitude = json['altitude'],
        timestamp = DateTime.parse(json['timestamp']);
}
