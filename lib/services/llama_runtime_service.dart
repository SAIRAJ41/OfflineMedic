import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaRuntimeService {
  LlamaRuntimeService._internal();
  static final LlamaRuntimeService instance = LlamaRuntimeService._internal();

  LlamaEngine? _engine;
  EngineSession? _session;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

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
          // FIX #2: Reduced from nCtx:2048, nBatch:512, nThreads:4
          // Old values were allocating ~200MB+ on top of model weights → OOM crash
          nCtx: 512,     // Our prompt is ~150 tokens; 512 is plenty
          nThreads: 2,   // 4 threads caused thermal throttling on mobile
          nBatch: 64,    // Much lighter memory footprint
        ),
      );

      // FIX #1: Do NOT create a session here anymore.
      // The old code created ONE session and reused it forever, causing the
      // KV cache to fill up and the OS to kill the process on the first inference call.
      // Sessions are now created fresh inside generate() and disposed after each call.

      _isLoaded = true;
      debugPrint('LlamaRuntime: ✅ Model loaded successfully');
    } catch (e) {
      debugPrint('LlamaRuntime: ❌ Initialization failed: $e');
      throw Exception('Llama runtime initialization failed: $e');
    }
  }

  Future<String> generate(String prompt) async {
    if (!_isLoaded || _engine == null) {
      throw Exception('Llama runtime not initialized');
    }

    // FIX #1: Always start with a clean session.
    // Disposes any leftover session from a previous call (e.g. a timed-out one)
    // and creates a brand new one with an empty KV cache.
    await _session?.dispose();
    _session = null;
    _session = await _engine!.createSession();

    final buffer = StringBuffer();
    debugPrint('LlamaRuntime: Generation started');
    debugPrint('LlamaRuntime: Prompt length: ${prompt.length} characters');

    final stopwatch = Stopwatch()..start();
    bool firstTokenReceived = false;
    int tokenCount = 0;

    try {
      await for (final event in _session!
          .generate(
            prompt: prompt,
            maxTokens: 128,
            sampler: const SamplerParams(
              temperature: 0.2,
              topP: 0.9,
            ),
          )
          .timeout(const Duration(seconds: 45), onTimeout: (sink) {
        sink.addError(TimeoutException(
            'AI response took too long. Using safe fallback guidance.'));
      })) {
        if (stopwatch.elapsed.inSeconds > 90) {
          debugPrint(
              'LlamaRuntime: Generation timeout (90s overall). Stopping.');
          throw TimeoutException(
              'AI response took too long. Using safe fallback guidance.');
        }

        if (event is TokenEvent) {
          if (!firstTokenReceived) {
            firstTokenReceived = true;
            debugPrint(
                'LlamaRuntime: Time to first token: ${stopwatch.elapsedMilliseconds} ms');
          }
          tokenCount++;
          if (tokenCount <= 10) {
            debugPrint('LlamaRuntime: Token $tokenCount: ${event.text}');
          }

          buffer.write(event.text);
          final text = buffer.toString();

          if (text.contains('<end_of_turn>') ||
              text.contains('</s>') ||
              text.contains('<eos>')) {
            break;
          }

          final first = text.indexOf('{');
          final last = text.lastIndexOf('}');
          if (first != -1 && last > first) {
            break; // Stop as soon as JSON object is closed
          }
        } else if (event is DoneEvent) {
          if (event.trailingText.isNotEmpty) {
            buffer.write(event.trailingText);
          }
        }
      }
    } catch (e) {
      debugPrint('LlamaRuntime: Generation error: $e');
      rethrow;
    } finally {
      stopwatch.stop();
      debugPrint('LlamaRuntime: Total generated tokens: $tokenCount');
      debugPrint(
          'LlamaRuntime: Generation time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('LlamaRuntime: Generation completed');

      // Always clean up the session after inference to free KV cache memory
      await _session?.dispose();
      _session = null;
    }

    return buffer.toString();
  }

  /// FIX #3: Exposed so GemmaService can cancel a running session on timeout
  /// instead of letting it drain RAM in the background.
  Future<void> disposeSession() async {
    await _session?.dispose();
    _session = null;
    debugPrint('LlamaRuntime: Session disposed externally');
  }

  Future<void> dispose() async {
    await _session?.dispose();
    await _engine?.dispose();
    _session = null;
    _engine = null;
    _isLoaded = false;
    debugPrint('LlamaRuntime: Engine fully disposed');
  }
}