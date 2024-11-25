class RocketSnapshot {
  final double latitude;
  final double longitude;
  final double altitude;
  final double? verticalVelocity;
  final DateTime timestamp;

  RocketSnapshot({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.verticalVelocity,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'verticalVelocity': verticalVelocity,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RocketSnapshot.fromJson(Map<String, dynamic> json) => RocketSnapshot(
        latitude: json['latitude'],
        longitude: json['longitude'],
        altitude: json['altitude'],
        verticalVelocity: json['verticalVelocity'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
