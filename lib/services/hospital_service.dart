import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/hospital.dart';

class HospitalService {
  static List<Hospital>? _cachedHospitals;

  /// Loads hospitals with enhanced data from the bundled JSON.
  /// Falls back to original data if enhanced data is not available.
  static Future<List<Hospital>> loadHospitals() async {
    if (_cachedHospitals != null) {
      return _cachedHospitals!;
    }

    try {
      const enhancedPath = 'data/Hospitals_data/hospitals_enhanced.json';
      final raw = await rootBundle.loadString(enhancedPath);
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;

      _cachedHospitals = _parseHospitals(decoded);
      return _cachedHospitals!;
    } catch (e) {
      // Fallback to original data
      const originalPath = 'data/Hospitals_data/hopitals_coordinates.json';
      final raw = await rootBundle.loadString(originalPath);
      final dynamic decoded = json.decode(raw);

      final List<dynamic> items = decoded is List
          ? decoded
          : decoded is Map && decoded['hospitals'] is List
          ? decoded['hospitals'] as List
          : const [];

      _cachedHospitals = _parseHospitals(items);
      return _cachedHospitals!;
    }
  }

  static List<Hospital> _parseHospitals(List<dynamic> items) {
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

      final name = parseString(
        it['name'] ?? it['hospital_name'] ?? it['hospital'] ?? it['facility'],
      );
      final lat = parseDouble(
        it['lat'] ?? it['latitude'] ?? it['Lat'] ?? it['Latitude'],
      );
      final lon = parseDouble(
        it['lon'] ??
            it['lng'] ??
            it['longitude'] ??
            it['Lon'] ??
            it['Longitude'],
      );
      final phone = parseString(
        it['phone'] ?? it['contact'] ?? it['number'] ?? it['Phone'],
      );

      if (name.isEmpty || lat == null || lon == null) continue;

      hospitals.add(
        Hospital(
          name: name,
          type: it['type']?.toString(),
          city: it['city']?.toString(),
          state: it['state']?.toString(),
          latitude: lat,
          longitude: lon,
          phone: phone,
          specializations:
              (it['specializations'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          rating: (it['rating'] as num?)?.toDouble() ?? 3.5,
          availableBeds: (it['availableBeds'] as num?)?.toInt() ?? 0,
          totalBeds: (it['totalBeds'] as num?)?.toInt() ?? 0,
          emergencyServices:
              (it['emergencyServices'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          operatingHours: it['operatingHours']?.toString(),
          occupancyRate: (it['occupancyRate'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return hospitals;
  }

  /// Filter hospitals by type (Government, Private, NGO, etc.)
  static List<Hospital> filterByType(List<Hospital> hospitals, String type) {
    if (type.isEmpty) return hospitals;
    return hospitals
        .where((h) => (h.type ?? '').toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Filter hospitals by specialization
  static List<Hospital> filterBySpecialization(
    List<Hospital> hospitals,
    String specialization,
  ) {
    if (specialization.isEmpty) return hospitals;
    return hospitals
        .where(
          (h) => h.specializations.any(
            (s) => s.toLowerCase().contains(specialization.toLowerCase()),
          ),
        )
        .toList();
  }

  /// Filter hospitals by minimum rating
  static List<Hospital> filterByRating(
    List<Hospital> hospitals,
    double minRating,
  ) {
    return hospitals.where((h) => h.rating >= minRating).toList();
  }

  /// Filter hospitals with available beds
  static List<Hospital> filterByAvailableBeds(List<Hospital> hospitals) {
    return hospitals.where((h) => h.availableBeds > 0).toList();
  }

  /// Search hospitals by name or city
  static List<Hospital> search(List<Hospital> hospitals, String query) {
    if (query.isEmpty) return hospitals;
    final q = query.toLowerCase();
    return hospitals
        .where(
          (h) =>
              h.name.toLowerCase().contains(q) ||
              (h.city ?? '').toLowerCase().contains(q) ||
              (h.state ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  /// Get unique hospital types
  static Set<String> getHospitalTypes(List<Hospital> hospitals) {
    return hospitals
        .map((h) => h.type ?? 'Other')
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  /// Get unique specializations
  static Set<String> getSpecializations(List<Hospital> hospitals) {
    final specs = <String>{};
    for (final h in hospitals) {
      specs.addAll(h.specializations);
    }
    return specs;
  }

  /// Get unique states
  static Set<String> getStates(List<Hospital> hospitals) {
    return hospitals
        .map((h) => h.state ?? 'Unknown')
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  /// Sort hospitals by distance from a given point
  static void sortByDistance(
    List<Hospital> hospitals, {
    required double lat,
    required double lng,
  }) {
    hospitals.sort((a, b) {
      final da = distanceKm(
        lat1: lat,
        lon1: lng,
        lat2: a.latitude,
        lon2: a.longitude,
      );
      final db = distanceKm(
        lat1: lat,
        lon1: lng,
        lat2: b.latitude,
        lon2: b.longitude,
      );
      return da.compareTo(db);
    });
  }

  /// Sort hospitals by rating (highest first)
  static void sortByRating(List<Hospital> hospitals) {
    hospitals.sort((a, b) => b.rating.compareTo(a.rating));
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

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);

  /// Rough bounding box for mainland India (+ islands). Drops obvious bad coords.
  static bool isLikelyIndia(double lat, double lng) {
    return lat >= 6.4 &&
        lat <= 37.2 &&
        lng >= 67.9 &&
        lng <= 97.8;
  }

  /// Keep hospitals that plausibly lie in India (works for nationwide JSON).
  static List<Hospital> filterIndiaBounds(List<Hospital> hospitals) {
    return hospitals
        .where((h) => isLikelyIndia(h.latitude, h.longitude))
        .toList();
  }

  /// True if [h] is within [maxKm] of the user point (great-circle distance).
  static bool isWithinKm(
    Hospital h, {
    required double userLat,
    required double userLng,
    required double maxKm,
  }) {
    return distanceKm(
          lat1: userLat,
          lon1: userLng,
          lat2: h.latitude,
          lon2: h.longitude,
        ) <=
        maxKm;
  }
}
