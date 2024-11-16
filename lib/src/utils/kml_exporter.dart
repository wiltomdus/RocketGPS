// lib/utils/kml_exporter.dart
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class KMLExporter {
  static Future<String?> exportPositions(List<Position> positions) async {
    try {
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Rocket Flight Path</name>
    <Style id="rocketPath">
      <LineStyle>
        <color>ff0000ff</color>
        <width>4</width>
      </LineStyle>
    </Style>
    <Placemark>
      <name>Flight Path</name>
      <styleUrl>#rocketPath</styleUrl>
      <LineString>
        <extrude>1</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>
${positions.map((pos) => '${pos.longitude},${pos.latitude},${pos.altitude}').join('\n')}
        </coordinates>
      </LineString>
    </Placemark>
    ${positions.map((pos) => '''
    <Placemark>
      <TimeStamp>
        <when>${pos.timestamp.toIso8601String()}</when>
      </TimeStamp>
      <Point>
        <coordinates>${pos.longitude},${pos.latitude},${pos.altitude}</coordinates>
      </Point>
    </Placemark>''').join('\n')}
  </Document>
</kml>''';

      // Get downloads directory
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);

      // Create filename with timestamp
      final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_');
      final filePath = '$downloadPath/rocket_flight_$timestamp.kml';

      // Write file
      final file = File(filePath);
      await file.writeAsString(kml);

      return filePath;
    } catch (e) {
      debugPrint('Error exporting KML: $e');
      return null;
    }
  }
}
