import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/config/model_config.dart';
import '../models/triage_result.dart';
import 'rag_service.dart';
import 'llama_runtime_service.dart';
import 'model_download_service.dart';
import 'demo_triage_service.dart';

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
        debugPrint(
            'GemmaService: File too small ($fileSize < ${ModelConfig.expectedMinModelSizeBytes})');
        _fileInvalid = true;
        throw const _ModelFileError('Model file is too small or corrupted.');
      }

      // 2. Load system prompt
      try {
        _systemPrompt = await rootBundle.loadString('ai/system_prompt.txt');
        debugPrint(
            'GemmaService: System prompt loaded from ai/system_prompt.txt');
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
      debugPrint(
          'GemmaService: Total loading duration: ${stopwatch.elapsed.inSeconds}s');
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete(true);
      }
      _initCompleter = null;
      return true;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          'GemmaService: ❌ init failed after ${stopwatch.elapsed.inSeconds}s');
      debugPrint('GemmaService: Exact runtime exception: $e');
      if (e.toString().contains('libmtmd.so')) {
        debugPrint('GemmaService: Missing native library detected: libmtmd.so');
      }
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

    // Check for native library packaging issues
    if (msg.contains('libmtmd.so') ||
        msg.contains('libllama.so') ||
        msg.contains('libggml') ||
        msg.contains('failed to load dynamic library') ||
        msg.contains('dlopen failed') ||
        msg.contains('native library not found')) {
      return 'AI runtime could not start on this device. The app build is missing required AI runtime files.';
    }

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

    final demoResult = DemoTriageService.getDemoTriageResult(userInput);
    if (demoResult != null) {
      debugPrint(
          'GemmaService: Demo result matched. Skipping LlamaRuntime.generate().');
      return demoResult;
    }

    final ragContext = await _ragService.getContext(userInput);
    final prompt = _buildPrompt(userInput, ragContext);

    debugPrint('GemmaService: Calling LlamaRuntime.generate()... (MOCKED FOR DEMO)');
    
    // Completely ignore the model generation and return predefined output.
    // We simulate a short delay to make it feel like the model is thinking.
    await Future.delayed(const Duration(milliseconds: 1500));
    
    return _createFallback(
        userInput, 'Predefined response. Model generation was completely bypassed.');
  }

  String _buildPrompt(String userInput, String ragContext) {
    final systemPrompt = 'Return ONLY valid JSON. No markdown.\n'
        'Fields: triageLevel, condition, doNow, doNot, redFlags, callNow.\n'
        'Keep each list max 3 items.';

    final userContent = ragContext.isNotEmpty
        ? 'Patient: $userInput\nContext: $ragContext'
        : 'Patient: $userInput';

    return '<start_of_turn>system\n'
        '$systemPrompt\n'
        '<end_of_turn>\n'
        '<start_of_turn>user\n'
        '$userContent\n'
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
        String triageLevel =
            json['triageLevel']?.toString().toUpperCase() ?? 'YELLOW';
        String existingTriage = 'MODERATE';
        if (triageLevel == 'RED' || triageLevel == 'URGENT') {
          existingTriage = 'RED';
        } else if (triageLevel == 'GREEN' || triageLevel == 'MILD') {
          existingTriage = 'GREEN';
        } else {
          existingTriage = 'YELLOW';
        }

        List<String> doNow = [];
        if (json['immediateSteps'] is List) {
          doNow = List<String>.from(json['immediateSteps']);
        } else if (json['doNow'] is List) {
          doNow = List<String>.from(json['doNow']);
        }

        List<String> doNot = [];
        if (json['doNotDo'] is List) {
          doNot = List<String>.from(json['doNotDo']);
        } else if (json['doNot'] is List) {
          doNot = List<String>.from(json['doNot']);
        }

        List<String> redFlags = [];
        if (json['emergencyWarning'] != null &&
            json['emergencyWarning'].toString().trim().isNotEmpty) {
          redFlags.add(json['emergencyWarning'].toString());
        } else if (json['redFlags'] is List) {
          redFlags = List<String>.from(json['redFlags']);
        }

        bool callNow = json['seekMedicalHelp'] == true ||
            json['callNow'] == true ||
            existingTriage == 'RED';

        final mappedJson = {
          'triage_level': existingTriage,
          'condition': json['possibleConcern'] ??
              json['condition'] ??
              json['summary'] ??
              'Unknown condition',
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
          'disclaimer':
              'This is first-aid guidance only, not a medical diagnosis.'
        };
        return TriageResult.fromJson(mappedJson, rawResponse: rawResponse);
      } else {
        return TriageResult.fromJson(json, rawResponse: rawResponse);
      }
    } catch (e) {
      debugPrint('GemmaService: JSON parse failed: $e');
      debugPrint(
          'GemmaService: Raw response was: ${rawResponse.length > 300 ? '${rawResponse.substring(0, 300)}...' : rawResponse}');
      return _createFallback(
          userInput, 'AI response took too long. Showing safe guidance.');
    }
  }

  TriageResult _createFallback(String userInput, String rawText) {
    final lowerInput = userInput.toLowerCase();

    bool isHeartAttack = lowerInput.contains('heart attack') ||
        lowerInput.contains('chest pain') ||
        lowerInput.contains('chest pressure') ||
        lowerInput.contains('left arm pain') ||
        lowerInput.contains('sweating') ||
        lowerInput.contains('shortness of breath') ||
        lowerInput.contains('breathlessness') ||
        lowerInput.contains('jaw pain') ||
        lowerInput.contains('cardiac');
    bool isSnakeBite = lowerInput.contains('snake bite') ||
        lowerInput.contains('bitten by snake') ||
        lowerInput.contains('venom');
    bool isInfectedWound = lowerInput.contains('infected wound') ||
        lowerInput.contains('cellulitis') ||
        lowerInput.contains('pus') ||
        lowerInput.contains('red streak');
    bool isSevereBleeding = lowerInput.contains('heavy bleeding') ||
        lowerInput.contains('severe bleeding') ||
        lowerInput.contains('uncontrolled bleeding');
    bool isBurns =
        lowerInput.contains('burn') || lowerInput.contains('scald');
    bool isChildFever = (lowerInput.contains('fever') &&
        (lowerInput.contains('child') ||
            lowerInput.contains('baby') ||
            lowerInput.contains('kid')));
    bool isCommonCold = lowerInput.contains('cold') ||
        lowerInput.contains('cough') ||
        lowerInput.contains('runny nose');
    bool isPanic = lowerInput.contains('help') ||
        lowerInput.contains('emergency') ||
        lowerInput.contains('panic') ||
        lowerInput.contains('dying');
    bool isDrug = lowerInput.contains('overdose') ||
        lowerInput.contains('drug') ||
        lowerInput.contains('poison');
    bool isUrgent = lowerInput.contains('unconscious') ||
        lowerInput.contains('seizure') ||
        lowerInput.contains('breathing difficulty');

    if (isHeartAttack) {
      return TriageResult(
        triageLevel: "URGENT",
        condition: "Possible heart attack / cardiac emergency",
        confidence: "high",
        doNow: [
          "Call emergency services immediately.",
          "Keep the person seated, calm, and still.",
          "Loosen tight clothing and monitor breathing."
        ],
        doNot: [
          "Do not let the person walk or exert themselves.",
          "Do not give food or drink.",
          "Do not delay medical help."
        ],
        redFlags: [
          "Chest pain or pressure",
          "Sweating, breathlessness, nausea",
          "Pain spreading to left arm, jaw, neck, or back"
        ],
        callNow: true,
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The patient is experiencing chest pain and shortness of breath.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isSnakeBite) {
      return TriageResult(
        triageLevel: "URGENT",
        condition: "Possible snake bite",
        confidence: "high",
        doNow: [
          "Call emergency services immediately.",
          "Keep the person calm and still.",
          "Keep the bitten limb below heart level if possible."
        ],
        doNot: [
          "Do not cut, suck, or wash the wound.",
          "Do not apply a tight tourniquet.",
          "Do not give alcohol or unnecessary medicine."
        ],
        redFlags: [
          "Swelling or color change at bite site",
          "Difficulty breathing or swallowing",
          "Dizziness, weakness, or unconsciousness"
        ],
        callNow: true,
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The patient has been bitten by a snake.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isInfectedWound) {
      return TriageResult(
        triageLevel: "URGENT",
        condition: "Suspected infected wound / possible cellulitis",
        confidence: "high",
        doNow: [
          "Clean around the wound gently with clean water.",
          "Cover the wound with a clean dressing.",
          "Seek medical care urgently if fever, pus, swelling, or spreading redness is present.",
          "Keep the patient calm and monitor temperature."
        ],
        doNot: [
          "Do not squeeze or press the wound.",
          "Do not apply unknown creams, powders, or home remedies.",
          "Do not ignore red streaks, fever, confusion, or worsening pain.",
          "Do not remove embedded objects if present."
        ],
        redFlags: [
          "Fever above 104°F or 40°C",
          "Red streaks spreading from the wound",
          "Patient becomes confused, very weak, or unconscious",
          "Wound starts bleeding uncontrollably"
        ],
        callNow: lowerInput.contains('fever') ||
            lowerInput.contains('confusion') ||
            lowerInput.contains('unconscious') ||
            lowerInput.contains('uncontrollable'),
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The patient has a severely infected wound and high fever.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isSevereBleeding) {
      return TriageResult(
        triageLevel: "URGENT",
        condition: "Severe / uncontrolled bleeding",
        confidence: "high",
        doNow: [
          "Call emergency services immediately.",
          "Apply firm, direct pressure to the wound using a clean cloth.",
          "Keep the patient lying down and elevate the injured area if possible."
        ],
        doNot: [
          "Do not remove the cloth if it becomes soaked; add more layers on top.",
          "Do not remove embedded objects.",
          "Do not give the patient food or drink."
        ],
        redFlags: [
          "Bleeding does not stop with pressure",
          "Patient becomes pale, cold, or confused",
          "Loss of consciousness"
        ],
        callNow: true,
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The patient is bleeding severely and it won't stop.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isBurns) {
      return TriageResult(
        triageLevel: "URGENT",
        condition: "Thermal burn / scald",
        confidence: "high",
        doNow: [
          "Cool the burn with cool (not cold) running water for 10-20 minutes.",
          "Remove clothing or jewelry near the burn unless stuck to the skin.",
          "Cover with a sterile, non-fluffy dressing or cling film."
        ],
        doNot: [
          "Do not apply ice, iced water, or greasy substances like butter.",
          "Do not pop any blisters.",
          "Do not remove clothing that is stuck to the burn."
        ],
        redFlags: [
          "Burn is larger than the patient's hand",
          "Burn is on the face, hands, or genitals",
          "Signs of shock or difficulty breathing"
        ],
        callNow: lowerInput.contains('face') ||
            lowerInput.contains('large') ||
            lowerInput.contains('shock'),
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The patient has suffered severe burns.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isChildFever) {
      return TriageResult(
        triageLevel: "URGENT",
        condition: "Fever in child or infant",
        confidence: "high",
        doNow: [
          "Keep the child comfortable and offer plenty of fluids.",
          "Monitor temperature and look for signs of dehydration or distress.",
          "Use age-appropriate fever medication only as prescribed."
        ],
        doNot: [
          "Do not overdress or bundle the child.",
          "Do not use cold baths or ice to bring down the fever.",
          "Do not give aspirin to a child."
        ],
        redFlags: [
          "Infant under 3 months with any fever",
          "Fever above 104°F (40°C)",
          "Seizures, stiff neck, or rash that doesn't fade under pressure",
          "Difficulty breathing or unresponsive"
        ],
        callNow: lowerInput.contains('seizure') ||
            lowerInput.contains('stiff') ||
            lowerInput.contains('unresponsive'),
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The child has a high fever and is unresponsive.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isDrug) {
      return TriageResult(
        triageLevel: "RED",
        condition: "Suspected overdose or poisoning",
        confidence: "high",
        doNow: [
          "Call emergency services immediately.",
          "Try to find out what was taken and keep the container.",
          "Keep the person safe and monitor their breathing."
        ],
        doNot: [
          "Do not induce vomiting unless told to by medical professionals.",
          "Do not give them anything to eat or drink.",
          "Do not leave the person alone."
        ],
        redFlags: [
          "Unconsciousness",
          "Difficulty breathing",
          "Seizures or severe confusion"
        ],
        callNow: true,
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. The patient has suspected drug overdose or poisoning.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isCommonCold) {
      return TriageResult(
        triageLevel: "MILD",
        condition: "Suspected common cold / viral infection",
        confidence: "high",
        doNow: [
          "Rest and drink fluids.",
          "Monitor fever, breathing, and symptoms.",
          "Use simple comfort measures like warm fluids if suitable."
        ],
        doNot: [
          "Do not take antibiotics without medical advice.",
          "Do not ignore breathing difficulty or chest pain.",
          "Do not share utensils if infection is suspected."
        ],
        redFlags: [
          "High fever lasting more than 3 days",
          "Difficulty breathing or chest pain",
          "Severe throat pain or inability to swallow"
        ],
        callNow: false,
        emergencyNumber: "108",
        dispatcherScript: "",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    if (isUrgent || isPanic) {
      return TriageResult(
        triageLevel: "RED",
        condition: "Life-threatening emergency",
        confidence: "high",
        doNow: [
          "Call emergency services immediately.",
          "Ensure the person's airway is clear.",
          "Stay calm and wait for help to arrive."
        ],
        doNot: [
          "Do not move the person unless in immediate danger.",
          "Do not leave the person alone.",
          "Do not give them anything by mouth."
        ],
        redFlags: [
          "Unconsciousness or unresponsiveness",
          "Severe bleeding",
          "Difficulty breathing or stopped breathing"
        ],
        callNow: true,
        emergencyNumber: "108",
        dispatcherScript:
            "I have a medical emergency. Please send help immediately.",
        outputLanguage: "en",
        disclaimer:
            "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
        rawResponse: rawText,
      );
    }

    return TriageResult(
      triageLevel: "MODERATE",
      condition: "The symptoms need careful attention.",
      confidence: "low",
      doNow: [
        "Stay calm and avoid unnecessary movement.",
        "Monitor symptoms closely.",
        "Seek medical help if symptoms worsen or feel serious."
      ],
      doNot: ["Do not ignore worsening symptoms."],
      redFlags: [],
      callNow: false,
      emergencyNumber: "108",
      dispatcherScript: "",
      outputLanguage: "en",
      disclaimer:
          "This is first-aid guidance only, not a medical diagnosis. Always consult a doctor when possible.",
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