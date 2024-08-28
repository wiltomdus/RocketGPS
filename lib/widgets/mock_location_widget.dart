import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';

class MockLocationInstructions extends StatelessWidget {
  const MockLocationInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mock Location Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "To use an external GPS device, please follow these steps:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("1. Enable Developer Mode:"),
            const Text("   - Go to Settings > About Phone."),
            const Text("   - Tap 'Build number' seven times to enable Developer Mode."),
            const SizedBox(height: 10),
            const Text("2. Set Mock Location:"),
            const Text("   - Go to Developer Options."),
            const Text("   - Scroll down to 'Mock location app'."),
            const Text("   - Select this app from the list."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: openDeveloperSettings,
              child: const Text("Open Developer Settings"),
            ),
          ],
        ),
      ),
    );
  }

  void openDeveloperSettings() {
    const AndroidIntent intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
    );
    intent.launch();
  }
}
