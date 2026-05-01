import '../models/triage_result.dart';

class GemmaService {

  /// MOCK RESPONSE (REMOVE LATER)
  static Future<TriageResult> analyze(String input) async {
    await Future.delayed(const Duration(seconds: 2));

    return TriageResult.fromJson({
      "triage_level": "URGENT",
      "condition": "Suspected cellulitis with systemic infection",
      "confidence": "high",
      "do_now": [
        "Clean wound",
        "Apply antiseptic"
      ],
      "do_not": [],
      "red_flags": [],
      "emergency": {
        "call_now": true,
        "number": "108"
      }
    });

    /// TODO (TEAMMATE - GEMMA INTEGRATION):
    /// Replace mock with:
    /// - Send input text / voice / image
    /// - Get JSON response from model
  }
}