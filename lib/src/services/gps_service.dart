import 'dart:math';
import 'package:geolocator/geolocator.dart';

class GPSService {
  Position? _phonePosition;
  double? _rocketLatitude;
  double? _rocketLongitude;
  double? _previousAltitude;
  DateTime? _previousTimestamp;
  double? _verticalVelocity;

  // Existing permission and location methods
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    _phonePosition = await Geolocator.getCurrentPosition();
    return _phonePosition!;
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream();
  }

  // Position update methods
  void updatePhonePosition(Position position) {
    _phonePosition = position;
  }

  void updateRocketPosition(double lat, double lon, double alt) {
    _rocketLatitude = lat;
    _rocketLongitude = lon;
    _calculateVerticalVelocity(alt);
  }

  // Calculation methods
  double calculateDistance() {
    if (_phonePosition == null || _rocketLatitude == null || _rocketLongitude == null) {
      return 0.0;
    }

    return Geolocator.distanceBetween(
      _phonePosition!.latitude,
      _phonePosition!.longitude,
      _rocketLatitude!,
      _rocketLongitude!,
    );
  }

  double? calculateBearing() {
    if (_phonePosition == null || _rocketLatitude == null || _rocketLongitude == null) {
      return null;
    }

    final lat1 = _phonePosition!.latitude * pi / 180;
    final lon1 = _phonePosition!.longitude * pi / 180;
    final lat2 = _rocketLatitude! * pi / 180;
    final lon2 = _rocketLongitude! * pi / 180;

    final y = sin(lon2 - lon1) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    final bearing = atan2(y, x);

    return (bearing * 180 / pi + 360) % 360;
  }

  void _calculateVerticalVelocity(double currentAltitude) {
    final now = DateTime.now();

    if (_previousAltitude != null && _previousTimestamp != null) {
      final timeDelta = now.difference(_previousTimestamp!).inMilliseconds / 1000;
      final altitudeDelta = currentAltitude - _previousAltitude!;
      final velocityMps = altitudeDelta / timeDelta;
      _verticalVelocity = velocityMps * 3.28084; // Convert to ft/s
    }

    _previousAltitude = currentAltitude;
    _previousTimestamp = now;
  }

  // Getters
  double? get verticalVelocity => _verticalVelocity;
  bool get hasValidPositions => _phonePosition != null && _rocketLatitude != null && _rocketLongitude != null;
}
