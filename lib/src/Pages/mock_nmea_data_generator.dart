import 'dart:async';

class MockNmeaDataGenerator {
  StreamController<String> _nmeaStreamController = StreamController<String>.broadcast();

  MockNmeaDataGenerator() {
    _startGeneratingData();
  }

  Stream<String> get nmeaStream => _nmeaStreamController.stream;

  void _startGeneratingData() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      // Use the pre-formatted NMEA string
      String mockData = "\$GPGGA,123519,4530.6168,N,07333.7769,W,1,08,0.9,545.4,M,46.9,M,,*47";
      _nmeaStreamController.add(mockData);
    });
  }

  void dispose() {
    _nmeaStreamController.close();
  }
}
