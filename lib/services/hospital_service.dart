import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/hospital.dart';

class HospitalService {
  /// Loads hospital coordinates from the bundled JSON in `data/Hospitals_data`.
  ///
  /// Uses: `data/Hospitals_data/hopitals_coordinates.json`
  /// (note: filename has a typo in the repo).
  static Future<List<Hospital>> loadHospitals() async {
    const jsonAssetPath = 'data/Hospitals_data/hopitals_coordinates.json';

    final raw = await rootBundle.loadString(jsonAssetPath);
    final dynamic decoded = json.decode(raw);

    final List<dynamic> items = decoded is List
        ? decoded
        : decoded is Map && decoded['hospitals'] is List
            ? decoded['hospitals'] as List
            : const [];

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.trim());
      return null;
    }

    String parseString(dynamic v) => (v ?? '').toString().trim();

    final hospitals = <Hospital>[];
    for (final it in items) {
      if (it is! Map) continue;

      final name = parseString(it['name'] ??
          it['hospital_name'] ??
          it['hospital'] ??
          it['facility']);
      final lat = parseDouble(
          it['lat'] ?? it['latitude'] ?? it['Lat'] ?? it['Latitude']);
      final lon = parseDouble(it['lon'] ??
          it['lng'] ??
          it['longitude'] ??
          it['Lon'] ??
          it['Longitude']);
      final phone = parseString(
          it['phone'] ?? it['contact'] ?? it['number'] ?? it['Phone']);

      if (name.isEmpty || lat == null || lon == null) continue;

      hospitals.add(
        Hospital(
          name: name,
          latitude: lat,
          longitude: lon,
          phone: phone,
        ),
      );
    }

    return hospitals;
  }

  /// Computes distance in kilometers between two WGS84 points.
  static double distanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const r = 6371.0; // Earth radius in km

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
