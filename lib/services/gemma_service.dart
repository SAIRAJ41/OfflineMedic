import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/config/model_config.dart';
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
  bool get isLoaded => _isLoaded;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadError;
  String? get loadError => _loadError;

  /// True if loading failed due to invalid/missing file (not a runtime error).
  bool _fileInvalid = false;
  bool get fileInvalid => _fileInvalid;

  Completer<bool>? _initCompleter;

  String _systemPrompt = _fallbackPrompt;

  static const _fallbackPrompt =
      'You are OfflineMedic, an offline emergency triage assistant used in India. '
      'Given a patient description, respond ONLY with a valid JSON object. '
      'Do NOT use markdown (like ```json). Do NOT add text outside JSON. '
      'For head injury, recommend urgent help if red flags exist (loss of consciousness, vomiting, confusion, bleeding, seizure, severe headache, worsening symptoms). '
      'Format strictly like this:\n'
      '{\n'
      '  "triageLevel": "RED|YELLOW|GREEN",\n'
      '  "summary": "short summary of the situation",\n'
      '  "possibleConcern": "possible medical concern",\n'
      '  "immediateSteps": ["step 1", "step 2"],\n'
      '  "doNotDo": ["thing to avoid"],\n'
      '  "seekMedicalHelp": true|false,\n'
      '  "emergencyWarning": "when to call emergency services"\n'
      '}';

  Future<bool> initialize() async {
    if (_isLoaded) return true;

    // If already loading, wait for the same Future
    if (_isLoading && _initCompleter != null) {
      debugPrint('GemmaService: initialize() already in progress, waiting...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<bool>();
    _isLoading = true;
    _loadError = null;
    _fileInvalid = false;

    final stopwatch = Stopwatch()..start();
    debugPrint('GemmaService: initialize() started at ${DateTime.now()}');

    try {
      // 1. Validate model file before loading
      final modelFile = await ModelDownloadService.instance.getModelFile();
      final modelPath = modelFile.path;
      final fileExists = modelFile.existsSync();
      debugPrint('GemmaService: Model path = $modelPath');
      debugPrint('GemmaService: Model file exists = $fileExists');

      if (!fileExists) {
        _fileInvalid = true;
        throw const _ModelFileError('Model file not found.');
      }

      final fileSize = modelFile.lengthSync();
      debugPrint('GemmaService: Model file size = $fileSize bytes');

      if (fileSize < ModelConfig.expectedMinModelSizeBytes) {
        debugPrint('GemmaService: File too small ($fileSize < ${ModelConfig.expectedMinModelSizeBytes})');
        _fileInvalid = true;
        throw const _ModelFileError('Model file is too small or corrupted.');
      }

      // 2. Load system prompt
      try {
        _systemPrompt = await rootBundle.loadString('ai/system_prompt.txt');
        debugPrint('GemmaService: System prompt loaded from ai/system_prompt.txt');
      } catch (e) {
        debugPrint('GemmaService: System prompt file missing, using fallback');
        _systemPrompt = _fallbackPrompt;
      }

      // 3. Initialize llama runtime
      debugPrint('GemmaService: Calling LlamaRuntime.initialize()...');
      await _llamaRuntime.initialize(modelPath);
      debugPrint('GemmaService: LlamaRuntime.initialize() completed');

      // 4. Initialize RAG
      await _ragService.initialize();

      _isLoaded = true;
      _isLoading = false;
      stopwatch.stop();
      debugPrint('GemmaService: ✅ Ready! isLoaded = true');
      debugPrint('GemmaService: Loading finished at ${DateTime.now()}');
      debugPrint('GemmaService: Total loading duration: ${stopwatch.elapsed.inSeconds}s');
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(true);
      }
      _initCompleter = null;
      return true;
    } catch (e) {
      stopwatch.stop();
      debugPrint('GemmaService: ❌ init failed after ${stopwatch.elapsed.inSeconds}s: $e');
      _isLoading = false;
      _loadError = _classifyError(e);
      debugPrint('GemmaService: loadError = $_loadError');
      debugPrint('GemmaService: fileInvalid = $_fileInvalid');
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(false);
      }
      _initCompleter = null;
      return false;
    }
  }

  /// Classify errors into user-friendly messages.
  String _classifyError(dynamic e) {
    if (e is _ModelFileError) {
      return 'AI model file looks incomplete. Please download it again from setup.';
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('out of memory') ||
        msg.contains('memory') ||
        msg.contains('mmap') ||
        msg.contains('alloc')) {
      return 'AI model could not be loaded on this device.';
    }
    return 'AI model could not start on this device. Try restarting the app.';
  }

  Future<TriageResult> assess(String userInput) async {
    if (!_isLoaded) {
      throw Exception('Call initialize() first');
    }

    debugPrint('=== GEMMA SERVICE: Starting assessment ===');
    debugPrint('User input: $userInput');

    final ragContext = await _ragService.getContext(userInput);

    final prompt = _buildPrompt(userInput, ragContext);

    debugPrint('GemmaService: Calling LlamaRuntime.generate()...');
    try {
      final rawResponse = await _llamaRuntime.generate(prompt);
      debugPrint('GemmaService: Raw model output received (${rawResponse.length} chars)');
      debugPrint('GemmaService: Raw response preview: ${rawResponse.length > 200 ? '${rawResponse.substring(0, 200)}...' : rawResponse}');
      final result = _parseJson(rawResponse, userInput);
      debugPrint('GemmaService: Parsed result - ${result.triageLevel} / ${result.condition}');
      return result;
    } catch (e) {
      debugPrint('GemmaService: Inference error: $e');
      return _createFallback(userInput, e.toString());
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

  TriageResult _parseJson(String rawResponse, String userInput) {
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

      debugPrint('GemmaService: Parsing JSON...');
      final Map<String, dynamic> json = jsonDecode(cleaned);
      debugPrint('GemmaService: JSON parsed successfully');

      if (json.containsKey('triageLevel') || json.containsKey('summary')) {
        String triageLevel = json['triageLevel']?.toString().toUpperCase() ?? 'YELLOW';
        String existingTriage = 'MODERATE';
        if (triageLevel == 'RED' || triageLevel == 'URGENT') {
          existingTriage = 'URGENT';
        } else if (triageLevel == 'GREEN' || triageLevel == 'MILD') {
          existingTriage = 'MILD';
        }

        List<String> doNow = [];
        if (json['immediateSteps'] is List) {
          doNow = List<String>.from(json['immediateSteps']);
        }
        
        List<String> doNot = [];
        if (json['doNotDo'] is List) {
          doNot = List<String>.from(json['doNotDo']);
        }

        List<String> redFlags = [];
        if (json['emergencyWarning'] != null && json['emergencyWarning'].toString().trim().isNotEmpty) {
          redFlags.add(json['emergencyWarning'].toString());
        }

        bool callNow = json['seekMedicalHelp'] == true || existingTriage == 'URGENT';

        final mappedJson = {
          'triage_level': existingTriage,
          'condition': json['possibleConcern'] ?? json['summary'] ?? 'Unknown condition',
          'confidence': 'high',
          'do_now': doNow,
          'do_not': doNot,
          'red_flags': redFlags,
          'emergency': {
            'call_now': callNow,
            'number': '108',
            'dispatcher_script': ''
          },
          'output_language': 'en',
          'disclaimer': 'This is first-aid guidance only, not a medical diagnosis.'
        };
        return TriageResult.fromJson(mappedJson, rawResponse: rawResponse);
      } else {
        return TriageResult.fromJson(json, rawResponse: rawResponse);
      }
    } catch (e) {
      debugPrint('GemmaService: JSON parse failed: $e');
      debugPrint('GemmaService: Raw response was: ${rawResponse.length > 300 ? '${rawResponse.substring(0, 300)}...' : rawResponse}');
      return _createFallback(userInput, rawResponse);
    }
  }

  TriageResult _createFallback(String userInput, String rawText) {
    final lowerInput = userInput.toLowerCase();
    
    bool isHeadInjury = lowerInput.contains('head injury') || lowerInput.contains('hit head');
    bool hasRedFlags = lowerInput.contains('unconscious') || 
                       lowerInput.contains('vomiting') || 
                       lowerInput.contains('seizure') || 
                       lowerInput.contains('confusion') || 
                       lowerInput.contains('bleeding') || 
                       lowerInput.contains('severe headache') ||
                       lowerInput.contains('vision');
                       
    String triageLevel = "MODERATE";
    bool callNow = false;
    
    if (isHeadInjury && hasRedFlags) {
      triageLevel = "URGENT";
      callNow = true;
    } else if (lowerInput.contains('snake bite') || lowerInput.contains('snakebite')) {
      triageLevel = "URGENT";
      callNow = true;
    }

    return TriageResult(
      triageLevel: triageLevel,
      condition: "The symptoms need careful attention.",
      confidence: "low",
      doNow: [
        "Stay calm and avoid unnecessary movement.",
        "Monitor symptoms closely.",
        "Seek medical help if symptoms worsen or feel serious."
      ],
      doNot: ["Do not ignore worsening symptoms."],
      redFlags: callNow ? ["Seek emergency help immediately."] : [],
      callNow: callNow,
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
    _isLoading = false;
    _loadError = null;
    _fileInvalid = false;
    _initCompleter = null;
  }
}

/// Internal error type for model file validation failures.
class _ModelFileError implements Exception {
  final String message;
  const _ModelFileError(this.message);
  @override
  String toString() => '_ModelFileError: $message';
}
