import 'dart:convert';
import 'package:flutter/services.dart';

Future<String> getGoogleMapsApiKey() async {
  final String keysString = await rootBundle.loadString('assets/keys.json');
  final Map<String, dynamic> keys = jsonDecode(keysString);
  return keys['google_maps_api_key'];
}
