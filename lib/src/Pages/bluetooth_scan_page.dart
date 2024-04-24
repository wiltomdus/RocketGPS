import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:gps_link/src/services/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});
  static const routeName = '/bluetooth-scan';

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final List<BluetoothDevice> _devices = [];
  final List<BluetoothDevice> _connectedDevices = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
    ].request();

    print(statuses[Permission.location]);
    print(statuses[Permission.bluetooth]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
      ),
      body: FutureBuilder<List<BluetoothDevice>>(
        future: FlutterBluetoothSerial.instance.getBondedDevices(),
        builder: (BuildContext context, AsyncSnapshot<List<BluetoothDevice>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<BluetoothDevice> bondedDevices = snapshot.data!;
            return ListView.builder(
              itemCount: _devices.length + bondedDevices.length,
              itemBuilder: (context, index) {
                Color tileColor = Colors.white;
                if (index < bondedDevices.length) {
                  if (BluetoothService().connectedDevice != null &&
                      BluetoothService().connectedDevice!.address == bondedDevices[index].address) {
                    tileColor = Colors.green;
                  }
                  return ListTile(
                    title: Text(bondedDevices[index].name ?? 'Unknown device'),
                    subtitle: Text(bondedDevices[index].address),
                    trailing: const Text('Bonded'),
                    onTap: () async {
                      await BluetoothService().connectToDevice(bondedDevices[index]);
                    },
                  );
                } else {
                  int deviceIndex = index - bondedDevices.length;
                  if (BluetoothService().connectedDevice != null &&
                      BluetoothService().connectedDevice!.address == _devices[deviceIndex].address) {
                    tileColor = Colors.green;
                  }
                  return ListTile(
                    tileColor: tileColor,
                    title: Text(_devices[deviceIndex].name ?? 'Unknown device'),
                    subtitle: Text(_devices[deviceIndex].address),
                    trailing: const Text('Not bonded'),
                    onTap: () async {
                      if (!_devices[deviceIndex].isBonded) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Bond with device'),
                              content:
                                  Text('Do you want to bond with ${_devices[deviceIndex].name ?? 'Unknown device'}?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Bond'),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    print('Bonding device');
                                    await FlutterBluetoothSerial.instance
                                        .bondDeviceAtAddress(_devices[deviceIndex].address);
                                    print('Bonded device');
                                    await BluetoothService().connectToDevice(_devices[deviceIndex]);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  );
                }
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () async {
          FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
            setState(() {
              _devices.clear();
              _devices.add(result.device);
            });
          });
        },
      ),
    );
  }
}
