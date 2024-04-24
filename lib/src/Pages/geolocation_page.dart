import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_link/src/services/bluetooth_service.dart';
import 'package:gps_link/widgets/custom_card.dart';

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({super.key});

  static const routeName = '/geolocation';

  @override
  State<GeolocationPage> createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage> {
  BluetoothService bluetooth = BluetoothService();
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  Position? _currentPosition;
  Position? _rocketPosition;
  LatLng? get currentLocation =>
      _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null;

  @override
  void initState() {
    super.initState();
    // bluetooth.connect(bluetooth);
    // bluetooth.connection!.input?.listen((Uint8List data) {
    //   String nmeaData = ascii.decode(data);
    //   LatLng location = bluetooth.parseNmeaData(nmeaData);
    //   setState(() {
    //     _rocketPosition = Position(
    //         longitude: location.longitude,
    //         latitude: location.latitude,
    //         timestamp: DateTime.now(),
    //         accuracy: 0.0,
    //         altitude: 0.0,
    //         altitudeAccuracy: 0.0,
    //         heading: 0.0,
    //         headingAccuracy: 0.0,
    //         speed: 0.0,
    //         speedAccuracy: 0.0);
    //     markers = {
    //       Marker(
    //         markerId: MarkerId('rocket'),
    //         position: location,
    //         infoWindow: InfoWindow(title: 'Rocket'),
    //       ),
    //     };
    //   });
    // });
    _determinePosition().then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  //Refresh the map with the latest rocket location
  Future<void> refreshMapAsync() async {
    final GoogleMapController controller = await _controller.future;

    controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: currentLocation ?? const LatLng(45.5017, -73.5673),
      zoom: 12,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocation'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CustomCard(
            title: "Rocket Location",
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _determinePosition();
                refreshMapAsync();
              },
            ),
            children: Text(
              'Latitude: ${_currentPosition?.latitude ?? 'Unknown'}\n'
              'Longitude: ${_currentPosition?.longitude ?? 'Unknown'}\n'
              'Altitude: ${_currentPosition?.altitude ?? 'Unknown'}\n'
              'Accuracy: ${_currentPosition?.accuracy ?? 'Unknown'}\n'
              'Speed: ${_currentPosition?.speed ?? 'Unknown'}\n'
              'Speed Accuracy: ${_currentPosition?.speedAccuracy ?? 'Unknown'}\n'
              'Heading: ${_currentPosition?.heading ?? 'Unknown'}\n',
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(45.5017, -73.5673), // Defaults to Montreal if no location
                zoom: 10,
              ),
              markers: markers,
              myLocationEnabled: true, // Show the blue dot on the map
              myLocationButtonEnabled: true, // Show the button to center the map on the current location
            ),
          ),
        ],
      ),
    );
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
