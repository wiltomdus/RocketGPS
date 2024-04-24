import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:nmea/nmea.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Bluetooth {
  final FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

  StreamSubscription? _connectionSubscription;
  BluetoothConnection? connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  void connect(BluetoothDevice device) async {
    isConnecting = true;

    // Connect to the selected device
    await BluetoothConnection.toAddress(device.address).then((connection) {
      print('Connected to the device');
      connection = connection;
      isConnecting = false;

      // Handle when a disconnect happens
      _connectionSubscription = connection.input?.listen((Uint8List data) {
        // Handle your data here
      }, onDone: () {
        if (isConnected) {
          disconnect();
        }
      });
    }).catchError((error) {
      // Handle a failed connection
      print('Cannot connect, exception occurred');
      print(error);
    });

    // Listen for incoming data
    connection!.input?.listen((Uint8List data) {
      print('Received: ${ascii.decode(data)}');
      String nmeaData = ascii.decode(data);
      LatLng location = parseNmeaData(nmeaData);
      print('Received location: $location');
    });
  }

  void disconnect() async {
    // Close the connection
    await connection!.close();
    connection = null;

    // Cancel the subscription to the connection
    if (_connectionSubscription != null) {
      _connectionSubscription!.cancel();
      _connectionSubscription = null;
    }
  }

  void send(String data) async {
    // Send data
    connection!.output.add(utf8.encode("$data\r\n"));
    await connection!.output.allSent;
    print('Sent: $data');
  }

  LatLng parseNmeaData(String nmeaData) {
    final parser = NmeaDecoder();
    final sentence = parser.decode(nmeaData);
    return LatLng(0.0, 0.0);
    // if (sentence!.valid) {
    //   return LatLng(sentence.latitude!, sentence.longitude!);
    // } else {
    //   throw Exception('Invalid NMEA data');
    // }
  }
}
