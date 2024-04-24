import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:nmea/nmea.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() {
    return _instance;
  }
  BluetoothService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothConnection? connection;

  Future<void> connectToDevice(BluetoothDevice device) async {
    print('Connecting to the device');
    await BluetoothConnection.toAddress(device.address).then((connection) {
      print('Connected to the device');
      connectedDevice = device;
      this.connection = connection;
      // connection.input?.listen((Uint8List data) {
      //   print('Received: ${ascii.decode(data)}');
      // }).onDone(() {
      //   print('Disconnected by remote request');
      //   connectedDevice = null;
      //   this.connection = null;
      // });
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }
}
