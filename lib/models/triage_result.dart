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

  TriageResult({
    required this.triageLevel,
    required this.condition,
    required this.confidence,
    required this.doNow,
    required this.doNot,
    required this.redFlags,
    required this.callNow,
    required this.emergencyNumber,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    return TriageResult(
      triageLevel: json['triage_level'] ?? 'GREEN',
      condition: json['condition'] ?? '',
      confidence: json['confidence'] ?? 'low',
      doNow: List<String>.from(json['do_now'] ?? []),
      doNot: List<String>.from(json['do_not'] ?? []),
      redFlags: List<String>.from(json['red_flags'] ?? []),
      callNow: json['emergency']?['call_now'] ?? false,
      emergencyNumber: json['emergency']?['number'] ?? '108',
    );
  }

  factory TriageResult.fromModelOutput(String output) {
    try {
      final first = output.indexOf('{');
      final last = output.lastIndexOf('}');

      if (first == -1 || last == -1) {
        throw Exception('No JSON found');
      }

      final jsonString = output.substring(first, last + 1);
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return TriageResult.fromJson(decoded);
    } catch (e) {
      return TriageResult(
        triageLevel: 'GREEN',
        condition: 'Unable to analyze symptoms',
        confidence: 'low',
        doNow: ['Consult a doctor if symptoms continue'],
        doNot: [],
        redFlags: [],
        callNow: false,
        emergencyNumber: '108',
      );
    }
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
    };
  }

  /// Read from a SQLite row map.
  factory TriageResult.fromMap(Map<String, dynamic> map) {
    return TriageResult(
      triageLevel: map['triage_level'] ?? 'GREEN',
      condition: map['condition'] ?? '',
      confidence: map['confidence'] ?? 'low',
      doNow: _decodeJsonList(map['do_now']),
      doNot: _decodeJsonList(map['do_not']),
      redFlags: _decodeJsonList(map['red_flags']),
      callNow: (map['call_now'] ?? 0) == 1,
      emergencyNumber: map['emergency_number'] ?? '108',
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
}