// lib/services/gemma_service.dart

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/triage_result.dart';
import 'rag_service.dart';

class GemmaService {
  static final GemmaService _instance = GemmaService._internal();

  factory GemmaService() => _instance;

  GemmaService._internal();

  Llama? _llama;

  bool _isLoaded = false;

  final _ragService = RagService();

  static const _modelFileName = 'gemma4_offlinemedic.gguf';

  static const _systemPrompt =
      'You are OfflineMedic, an offline emergency triage assistant used in India. '
      'Given a patient description, respond ONLY with a valid JSON object: '
      '{"triage_level":"RED|YELLOW|GREEN","condition":"...","action":"...",'
      '"medicines":[],"call_emergency":true,"emergency_number":"108",'
      '"dispatcher_script":"...","warning_signs":[],"do_not_do":[]}. '
      'RED=life threatening. YELLOW=urgent. GREEN=minor. '
      'Respond ONLY in JSON. No other text.';

  // ------------------------------------------------------------
  // Initialize model
  // ------------------------------------------------------------

  Future<bool> initialize() async {
    try {
      final modelPath = await _getModelPath();

      await _copyModelIfNeeded(modelPath);

      _llama = Llama(
        modelPath,

        contextParams: ContextParams()
          ..nCtx = 2048
          ..nThreads = 4
          ..nBatch = 512,

        verbose: false,
      );

      await _ragService.initialize();

      _isLoaded = true;

      print('✅ GemmaService ready!');

      return true;
    } catch (e) {
      print('❌ GemmaService init failed: $e');

      return false;
    }
  }

  // ------------------------------------------------------------
  // Main assessment function
  // ------------------------------------------------------------

  Future<TriageResult> assess(String userInput) async {
    if (!_isLoaded || _llama == null) {
      throw Exception('Call initialize() first');
    }

    final ragContext = await _ragService.getContext(userInput);

    final prompt = _buildPrompt(
      userInput,
      ragContext,
    );

    final buffer = StringBuffer();

    _llama!.setPrompt(prompt);

    await for (final token in _llama!.generateText()) {
      buffer.write(token);

      final text = buffer.toString();

      final first = text.indexOf('{');
      final last = text.lastIndexOf('}');

      if (first != -1 && last > first) {
        break;
      }
    }

    return TriageResult.fromModelOutput(
      buffer.toString(),
    );
  }

  // ------------------------------------------------------------
  // Streaming response
  // ------------------------------------------------------------

  Stream<String> assessStream(String userInput) async* {
    if (!_isLoaded || _llama == null) {
      throw Exception('Call initialize() first');
    }

    final ragContext = await _ragService.getContext(userInput);

    final prompt = _buildPrompt(
      userInput,
      ragContext,
    );

    final buffer = StringBuffer();

    _llama!.setPrompt(prompt);

    await for (final token in _llama!.generateText()) {
      buffer.write(token);

      yield token;

      final text = buffer.toString();

      final first = text.indexOf('{');
      final last = text.lastIndexOf('}');

      if (first != -1 && last > first) {
        break;
      }
    }
  }

  // ------------------------------------------------------------
  // Build prompt
  // ------------------------------------------------------------

  String _buildPrompt(
    String userInput,
    String ragContext,
  ) {
    final userContent = ragContext.isNotEmpty
        ? 'Patient: $userInput\n\nRelevant context:\n$ragContext'
        : 'Patient: $userInput';

    return '<start_of_turn>system\n'
        '$_systemPrompt'
        '<end_of_turn>\n'
        '<start_of_turn>user\n'
        '$userContent'
        '<end_of_turn>\n'
        '<start_of_turn>model\n';
  }

  // ------------------------------------------------------------
  // Get model path
  // ------------------------------------------------------------

  Future<String> _getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();

    return p.join(
      dir.path,
      'models',
      _modelFileName,
    );
  }

  // ------------------------------------------------------------
  // Copy model from assets
  // ------------------------------------------------------------

  Future<void> _copyModelIfNeeded(String destPath) async {
    final file = File(destPath);

    if (await file.exists()) {
      return;
    }

    await file.parent.create(
      recursive: true,
    );

    print('First launch: copying model to device...');

    final data = await rootBundle.load(
      'assets/models/$_modelFileName',
    );

    final bytes = data.buffer.asUint8List();

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    print('✅ Model copied');
  }

  // ------------------------------------------------------------
  // Dispose
  // ------------------------------------------------------------

  void dispose() {
    _llama?.dispose();

    _isLoaded = false;
  }
}
