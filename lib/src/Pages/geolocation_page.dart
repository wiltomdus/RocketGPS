import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({super.key});

  static const routeName = '/geolocation';

  @override
  State<GeolocationPage> createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage> {
  final LatLng INITIAL_GPS_COORDINATE = const LatLng(40.00, -40.00);
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  Position? _currentPosition;
  LatLng? _lastNonZeroPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? get currentLocation => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : const LatLng(47, -81);

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  final bool _mapIsBeingTouched = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (position.latitude != 0.0 && position.longitude != 0.0) {
        setState(() {
          _currentPosition = position;
          _lastNonZeroPosition = LatLng(position.latitude, position.longitude);
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Cancel the stream subscription
    WakelockPlus.disable();
    super.dispose();
  }

  //Refresh the map with the latest rocket location
  Future<void> refreshMapAsync() async {
    final GoogleMapController controller = await _controller.future;

    controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: currentLocation ?? INITIAL_GPS_COORDINATE,
      zoom: 12,
    )));
  }

  void _showLocationDialog(String title, LatLng initialPosition, Function(LatLng) onConfirm) {
    final TextEditingController latController = TextEditingController(text: initialPosition.latitude.toString());
    final TextEditingController lngController = TextEditingController(text: initialPosition.longitude.toString());
    LatLng selectedPosition = initialPosition;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: latController,
                    decoration: const InputDecoration(labelText: "Latitude"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final lat = double.tryParse(value) ?? initialPosition.latitude;
                      setState(() {
                        selectedPosition = LatLng(lat, selectedPosition.longitude);
                      });
                    },
                  ),
                  TextField(
                    controller: lngController,
                    decoration: const InputDecoration(labelText: "Longitude"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final lng = double.tryParse(value) ?? initialPosition.longitude;
                      setState(() {
                        selectedPosition = LatLng(selectedPosition.latitude, lng);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
                      onMapCreated: (GoogleMapController controller) {},
                      markers: {
                        Marker(
                          markerId: MarkerId(title),
                          position: selectedPosition,
                          draggable: true,
                          onDragEnd: (LatLng newPosition) {
                            setState(() {
                              selectedPosition = newPosition;
                              latController.text = newPosition.latitude.toStringAsFixed(6);
                              lngController.text = newPosition.longitude.toStringAsFixed(6);
                            });
                          },
                        ),
                      },
                      onTap: (LatLng tappedPosition) {
                        setState(() {
                          selectedPosition = tappedPosition;
                          latController.text = tappedPosition.latitude.toStringAsFixed(6);
                          lngController.text = tappedPosition.longitude.toStringAsFixed(6);
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    onConfirm(selectedPosition);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert units
    final double speedMs = _currentPosition?.speed ?? 0.0; // Speed in m/s
    final double speedFtS = speedMs * 3.28084; // Speed in ft/s
    final double speedMach = speedMs / 343; // Speed in Mach
    final double altitudeFt = _currentPosition?.altitude != null
        ? _currentPosition!.altitude * 3.28084 // Convert altitude from meters to feet
        : 0.0;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _currentPosition == null
              ? const CircularProgressIndicator() // Show a loading indicator while waiting for position data
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (_mapIsBeingTouched) {
                      return true;
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () {
                                _showLocationDialog(
                                  'Set Ground Station Location',
                                  currentLocation ?? INITIAL_GPS_COORDINATE,
                                  (LatLng newPosition) {
                                    setState(() {
                                      markers.add(Marker(
                                        markerId: const MarkerId('ground_station'),
                                        position: newPosition,
                                        infoWindow: const InfoWindow(title: 'Ground Station'),
                                      ));
                                    });
                                    refreshMapAsync();
                                  },
                                );
                              },
                              child: const Column(
                                children: [
                                  Text(
                                    'Set Ground Station',
                                  ),
                                  Text(
                                    'Location',
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _showLocationDialog(
                                  'Set Launch Pad Location',
                                  currentLocation ?? INITIAL_GPS_COORDINATE,
                                  (LatLng newPosition) {
                                    setState(() {
                                      markers.add(Marker(
                                        markerId: const MarkerId('Launch Pad'),
                                        position: newPosition,
                                        infoWindow: const InfoWindow(title: 'Launch Pad'),
                                      ));
                                    });
                                    refreshMapAsync();
                                  },
                                );
                              },
                              child: const Column(
                                children: [
                                  Text(
                                    'Set Launch Pad',
                                  ),
                                  Text(
                                    'Location',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Current Altitude',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${altitudeFt.toStringAsFixed(2)} ft', // Altitude in ft
                          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${speedFtS.toStringAsFixed(1)} ft/s', // Speed in m/s
                          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mach ${speedMach.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _latitudeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Latitude",
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _longitudeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Longitude",
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                const Icon(Icons.gps_fixed, size: 40),
                                Text(
                                  '±${_currentPosition!.accuracy.toStringAsFixed(2)}m',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            Column(
                              children: <Widget>[
                                const Icon(Icons.explore, size: 40),
                                Text(
                                  '${_currentPosition!.heading.toStringAsFixed(2)}°',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // GestureDetector(
                        //   onPanDown: (_) {
                        //     setState(() {
                        //       _mapIsBeingTouched = true;
                        //     });
                        //   },
                        //   onPanEnd: (_) {
                        //     setState(() {
                        //       _mapIsBeingTouched = false;
                        //     });
                        //   },
                        //   child: SizedBox(
                        //     height: 300,
                        //     child: GoogleMap(
                        //       mapType: MapType.hybrid,
                        //       initialCameraPosition: CameraPosition(
                        //         target: currentLocation ?? INITIAL_GPS_COORDINATE,
                        //         zoom: 12,
                        //       ),
                        //       onMapCreated: (GoogleMapController controller) {
                        //         _controller.complete(controller);
                        //       },
                        //       markers: markers,
                        //       onTap: (_) {
                        //         setState(() {
                        //           _mapIsBeingTouched = true;
                        //         });
                        //       },
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
