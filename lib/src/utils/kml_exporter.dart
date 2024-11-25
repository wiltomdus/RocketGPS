// lib/utils/kml_exporter.dart
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class KMLExporter {
  static Future<String?> exportPositions(List<Position> positions) async {
    if (positions.isEmpty) {
      debugPrint('No positions to export');
      return 'no positions to export';
    }

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
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOCUMENTS);

      final rocketGPSPath = '$downloadPath/RocketGPS';
      final rocketGPSDir = Directory(rocketGPSPath);

      // Create directory if it doesn't exist
      if (!await rocketGPSDir.exists()) {
        await rocketGPSDir.create();
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_');
      final filePath = '$rocketGPSPath/rocket_flight_$timestamp.kml';

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
