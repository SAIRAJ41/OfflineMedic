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
      triageLevel: json['triage_level'],
      condition: json['condition'],
      confidence: json['confidence'],
      doNow: List<String>.from(json['do_now']),
      doNot: List<String>.from(json['do_not']),
      redFlags: List<String>.from(json['red_flags']),
      callNow: json['emergency']['call_now'],
      emergencyNumber: json['emergency']['number'],
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
}