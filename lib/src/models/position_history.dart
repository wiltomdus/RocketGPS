class PositionHistory {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  PositionHistory({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PositionHistory.fromJson(Map<String, dynamic> json) => PositionHistory(
        latitude: json['latitude'],
        longitude: json['longitude'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
