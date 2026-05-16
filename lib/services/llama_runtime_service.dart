import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaRuntimeService {
  LlamaRuntimeService._internal();
  static final LlamaRuntimeService instance = LlamaRuntimeService._internal();

  LlamaEngine? _engine;
  EngineSession? _session;
  bool _isLoaded = false;

  Future<void> initialize(String modelPath) async {
    if (_isLoaded) return;
    try {
      debugPrint('LlamaRuntime: initialize() started');
      debugPrint('LlamaRuntime: Loading model from: $modelPath');

      String libPath = 'libllama.so';
      if (Platform.isIOS || Platform.isMacOS) {
        libPath = '<process>';
      } else if (Platform.isWindows) {
        libPath = 'llama.dll';
      }

      _engine = await LlamaEngine.spawn(
        libraryPath: libPath,
        modelParams: ModelParams(path: modelPath),
        contextParams: const ContextParams(
          nCtx: 2048,
          nThreads: 4,
          nBatch: 512,
        ),
      );

      _session = await _engine!.createSession();
      _isLoaded = true;
      debugPrint('LlamaRuntime: ✅ Model loaded successfully');
    } catch (e) {
      debugPrint('LlamaRuntime: ❌ Initialization failed: $e');
      throw Exception('Llama runtime initialization failed: $e');
    }
  }

  Future<String> generate(String prompt) async {
    if (!_isLoaded || _engine == null || _session == null) {
      throw Exception('Llama runtime not initialized');
    }

    final buffer = StringBuffer();

    await for (final event in _session!.generate(
      prompt: prompt,
      maxTokens: 1024,
    )) {
      if (event is TokenEvent) {
        buffer.write(event.text);
        final text = buffer.toString();
        final first = text.indexOf('{');
        final last = text.lastIndexOf('}');
        if (first != -1 && last > first) {
          break; // Stop when JSON is closed
        }
      } else if (event is DoneEvent) {
        if (event.trailingText.isNotEmpty) {
          buffer.write(event.trailingText);
        }
      }
    }

    return buffer.toString();
  }

  Future<void> dispose() async {
    await _session?.dispose();
    await _engine?.dispose();
    _session = null;
    _engine = null;
    _isLoaded = false;
  }
}
