import 'package:flutter/material.dart';
import 'package:rocket_gps/src/Pages/geolocation_page.dart';
import 'package:rocket_gps/src/settings/settings_controller.dart';

class HomePage extends StatefulWidget {
  final SettingsController settingsController;

  const HomePage({super.key, required this.settingsController});

  static const routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rocket GPS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: const GeolocationPage(),
    );
  }
}
