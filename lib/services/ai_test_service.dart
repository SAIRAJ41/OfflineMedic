// lib/services/ai_test_service.dart
// Loads AI test results from ai/test_results.json for display.

import 'dart:convert';
import 'package:flutter/services.dart';

class AiTestService {
  AiTestService._internal();
  static final AiTestService instance = AiTestService._internal();

  Map<String, dynamic>? _data;

  /// Load test results from the bundled JSON asset.
  Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('ai/test_results.json');
      _data = jsonDecode(raw);
    } catch (e) {
      print('⚠️ AiTestService load failed: $e');
      _data = null;
    }
  }

  /// Returns a human-readable pass rate string, e.g. "8/10".
  /// Returns null if data is unavailable.
  String? getPassRate() {
    if (_data == null) return null;
    final passed = _data!['total_passed'];
    final total = _data!['total_tests'];
    if (passed == null || total == null) return null;
    return '$passed/$total';
  }

  /// Returns the percentage string, e.g. "80%".
  String? getPassPercentage() {
    return _data?['pass_rate']?.toString();
  }

  /// Returns the full list of test result entries.
  List<Map<String, dynamic>> getTestResults() {
    if (_data == null) return [];
    final results = _data!['test_results'];
    if (results is! List) return [];
    return results.cast<Map<String, dynamic>>();
  }
}
