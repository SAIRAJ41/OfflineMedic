import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/triage_result.dart';
import 'rag_service.dart';
import 'llama_runtime_service.dart';
import 'model_download_service.dart';

class GemmaService {
  GemmaService._internal();
  static final GemmaService instance = GemmaService._internal();

  final _ragService = RagService.instance;
  final _llamaRuntime = LlamaRuntimeService.instance;

  bool _isLoaded = false;

  String _systemPrompt = _fallbackPrompt;

  static const _fallbackPrompt =
      'You are OfflineMedic, an offline emergency triage assistant used in India. '
      'Given a patient description, respond ONLY with a valid JSON object: '
      '{"triage_level":"URGENT|MODERATE|MILD","condition":"...","confidence":"high|medium|low",'
      '"do_now":[],"do_not":[],"red_flags":[],'
      '"emergency":{"action_required":false,"call_now":false,"number":"108","dispatcher_script":""},'
      '"disclaimer":"This is first-aid guidance only, not a medical diagnosis."}. '
      'URGENT=life threatening. MODERATE=needs care within hours. MILD=home care sufficient. '
      'Respond ONLY in JSON. No other text.';

  Future<bool> initialize() async {
    if (_isLoaded) return true;

    try {
      try {
        _systemPrompt = await rootBundle.loadString('ai/system_prompt.txt');
        print('✅ System prompt loaded from ai/system_prompt.txt');
      } catch (e) {
        print('⚠️ System prompt file missing, using fallback');
        _systemPrompt = _fallbackPrompt;
      }

      final modelPath = await ModelDownloadService.instance.getModelPath();

      await _llamaRuntime.initialize(modelPath);

      await _ragService.initialize();

      _isLoaded = true;
      print('✅ GemmaService ready!');
      return true;
    } catch (e) {
      print('❌ GemmaService init failed: $e');
      return false;
    }
  }

  Future<TriageResult> assess(String userInput) async {
    if (!_isLoaded) {
      throw Exception('Call initialize() first');
    }

    final ragContext = await _ragService.getContext(userInput);

    final prompt = _buildPrompt(userInput, ragContext);

    try {
      final rawResponse = await _llamaRuntime.generate(prompt);
      return _parseJson(rawResponse);
    } catch (e) {
      print('❌ Inference error: $e');
      return _createFallback(e.toString());
    }
  }

  String _buildPrompt(String userInput, String ragContext) {
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

  TriageResult _parseJson(String rawResponse) {
    try {
      String cleaned = rawResponse
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      final first = cleaned.indexOf('{');
      final last = cleaned.lastIndexOf('}');

      if (first != -1 && last != -1 && last > first) {
        cleaned = cleaned.substring(first, last + 1);
      } else {
        throw Exception("No JSON found in response");
      }

      final Map<String, dynamic> json = jsonDecode(cleaned);
      return TriageResult.fromJson(json, rawResponse: rawResponse);
    } catch (e) {
      print("❌ JSON parse failed: $e");
      return _createFallback(rawResponse);
    }
  }

  TriageResult _createFallback(String rawText) {
    return TriageResult(
      triageLevel: "MODERATE",
      condition: "Analysis completed but format was unreadable.",
      confidence: "low",
      doNow: ["Review the raw response below if necessary.", "Consult a human doctor."],
      doNot: [],
      redFlags: [],
      callNow: false,
      emergencyNumber: "108",
      dispatcherScript: "",
      outputLanguage: "en",
      disclaimer: "This is first-aid guidance only.",
      rawResponse: rawText,
    );
  }

  void dispose() {
    _llamaRuntime.dispose();
    _isLoaded = false;
  }
}
