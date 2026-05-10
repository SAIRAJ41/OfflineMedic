import 'triage_result.dart';

/// A saved case in the local SQLite database.
/// Wraps a TriageResult with metadata (timestamp, input type, notes).
class CaseHistory {
  final int? id;
  final String inputText;
  final String inputType; // 'text', 'voice', 'image'
  final String? imagePath;
  final TriageResult result;
  final String? rawResponse;
  final String? notes;
  final DateTime createdAt;

  CaseHistory({
    this.id,
    required this.inputText,
    this.inputType = 'text',
    this.imagePath,
    required this.result,
    this.rawResponse,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    final triageMap = result.toMap();
    return {
      if (id != null) 'id': id,
      'input_text': inputText,
      'input_type': inputType,
      'image_path': imagePath,
      'triage_level': triageMap['triage_level'],
      'condition': triageMap['condition'],
      'confidence': triageMap['confidence'],
      'do_now': triageMap['do_now'],
      'do_not': triageMap['do_not'],
      'red_flags': triageMap['red_flags'],
      'call_now': triageMap['call_now'],
      'emergency_number': triageMap['emergency_number'],
      'raw_response': rawResponse,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Read from a SQLite row map.
  factory CaseHistory.fromMap(Map<String, dynamic> map) {
    return CaseHistory(
      id: map['id'] as int?,
      inputText: map['input_text'] ?? '',
      inputType: map['input_type'] ?? 'text',
      imagePath: map['image_path'],
      result: TriageResult.fromMap(map),
      rawResponse: map['raw_response'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
