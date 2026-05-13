import 'dart:convert';

class TriageResult {
  final String triageLevel;
  final String condition;
  final String confidence;
  final List<String> doNow;
  final List<String> doNot;
  final List<String> redFlags;
  final bool callNow;
  final String emergencyNumber;
  final String dispatcherScript;
  final String outputLanguage;
  final String disclaimer;
  final String rawResponse;

  TriageResult({
    required this.triageLevel,
    required this.condition,
    required this.confidence,
    required this.doNow,
    required this.doNot,
    required this.redFlags,
    required this.callNow,
    required this.emergencyNumber,
    required this.dispatcherScript,
    required this.outputLanguage,
    required this.disclaimer,
    required this.rawResponse,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json, {String rawResponse = ""}) {
    final emergency = json['emergency'] as Map<String, dynamic>? ?? {};

    return TriageResult(
      triageLevel: json['triage_level'] ?? 'MODERATE',
      condition: json['condition'] ?? 'Unknown condition',
      confidence: json['confidence'] ?? 'low',
      doNow: List<String>.from(json['do_now'] ?? []),
      doNot: List<String>.from(json['do_not'] ?? []),
      redFlags: List<String>.from(json['red_flags'] ?? []),
      callNow: emergency['call_now'] ?? false,
      emergencyNumber: emergency['number'] ?? '108',
      dispatcherScript: emergency['dispatcher_script'] ?? '',
      outputLanguage: json['output_language'] ?? 'en',
      disclaimer: json['disclaimer'] ?? 'This is first-aid guidance only.',
      rawResponse: rawResponse,
    );
  }

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'triage_level': triageLevel,
      'condition': condition,
      'confidence': confidence,
      'do_now': jsonEncode(doNow),
      'do_not': jsonEncode(doNot),
      'red_flags': jsonEncode(redFlags),
      'call_now': callNow ? 1 : 0,
      'emergency_number': emergencyNumber,
      'dispatcher_script': dispatcherScript,
      'output_language': outputLanguage,
      'disclaimer': disclaimer,
      'raw_response': rawResponse,
    };
  }

  /// Read from a SQLite row map.
  factory TriageResult.fromMap(Map<String, dynamic> map) {
    return TriageResult(
      triageLevel: map['triage_level'] ?? 'MODERATE',
      condition: map['condition'] ?? '',
      confidence: map['confidence'] ?? 'low',
      doNow: _decodeJsonList(map['do_now']),
      doNot: _decodeJsonList(map['do_not']),
      redFlags: _decodeJsonList(map['red_flags']),
      callNow: (map['call_now'] ?? 0) == 1,
      emergencyNumber: map['emergency_number'] ?? '108',
      dispatcherScript: map['dispatcher_script'] ?? '',
      outputLanguage: map['output_language'] ?? 'en',
      disclaimer: map['disclaimer'] ?? 'This is first-aid guidance only.',
      rawResponse: map['raw_response'] ?? '',
    );
  }

  static List<String> _decodeJsonList(dynamic value) {
    if (value == null || value == '') return [];
    try {
      return List<String>.from(jsonDecode(value));
    } catch (_) {
      return [];
    }
  }

  // Helper color logic based on user snippet
  String get triageColor {
    switch (triageLevel.toUpperCase()) {
      case "URGENT":   return "#EF4444"; // red
      case "MODERATE": return "#F59E0B"; // yellow
      case "MILD":     return "#22C55E"; // green
      default:         return "#F59E0B";
    }
  }
}