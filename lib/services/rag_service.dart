// lib/services/rag_service.dart
// Searches local SQLite database for relevant medical context
// before sending query to the AI model (RAG = Retrieval Augmented Generation)
//
// Now uses the shared DatabaseService instead of its own database.

import 'database_service.dart';

class RagService {
  RagService._internal();
  static final RagService instance = RagService._internal();

  // ── Call once at startup ───────────────────────────────────
  // No-op now — DatabaseService handles initialization & seeding.
  Future<void> initialize() async {
    print('✅ RagService ready (using shared DatabaseService)');
  }

  // ── Search DB for context matching user input ──────────────
  // Returns a string injected into the AI prompt
  Future<String> getContext(String userInput) async {
    try {
      final all = await DatabaseService.instance.getKnowledge();
      if (all.isEmpty) return '';

      final lower = userInput.toLowerCase();

      final matches = all.where((row) {
        final keywords = (row['keywords'] as String).split(',');
        return keywords.any((kw) => lower.contains(kw.trim().toLowerCase()));
      }).take(2).toList();

      if (matches.isEmpty) return '';

      return matches
          .map((r) => '[${r['condition']}]: ${r['facts']}')
          .join('\n\n');
    } catch (e) {
      print('RagService query error: $e');
      return '';
    }
  }
}