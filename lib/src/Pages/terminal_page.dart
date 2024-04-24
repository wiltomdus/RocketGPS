import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gps_link/src/services/bluetooth_service.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  static const routeName = '/terminal';

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  List<String> messages = [];
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    subscription = BluetoothService().connection?.input?.listen((Uint8List data) {
      print('Received: ${ascii.decode(data)}');
      // setState(() {
      //   messages.add(String.fromCharCodes(data));
      // });
      if (ascii.decode(data).contains('!')) {
        BluetoothService().connection!.close(); // Closing connection
        print('Disconnecting by local host');
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal')),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(messages[index]),
          );
        },
      ),
    );
  }
}
