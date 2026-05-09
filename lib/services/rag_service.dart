// lib/services/rag_service.dart
// Searches local SQLite database for relevant medical context
// before sending query to the AI model (RAG = Retrieval Augmented Generation)

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class RagService {
  static final RagService _instance = RagService._internal();
  factory RagService() => _instance;
  RagService._internal();

  Database? _db;

  // ── Call once at startup ───────────────────────────────────
  Future<void> initialize() async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'medic_rag.db');

      // Copy DB from assets to phone storage on first launch
      if (!await File(dbPath).exists()) {
        final bytes = await rootBundle.load('assets/db/medic_rag.db');
        await File(dbPath).writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
        print('✅ RAG database copied to device');
      }

      _db = await openDatabase(dbPath, readOnly: true);
      print('✅ RagService ready');
    } catch (e) {
      print('⚠️ RagService init failed: $e — continuing without RAG');
    }
  }

  // ── Search DB for context matching user input ──────────────
  // Returns a string injected into the AI prompt
  Future<String> getContext(String userInput) async {
    if (_db == null) return '';

    try {
      final lower = userInput.toLowerCase();
      final all   = await _db!.query('knowledge');

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