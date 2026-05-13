import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaRuntimeService {
  LlamaRuntimeService._internal();
  static final LlamaRuntimeService instance = LlamaRuntimeService._internal();

  Llama? _llama;
  bool _isLoaded = false;

  Future<void> initialize(String modelPath) async {
    if (_isLoaded) return;
    try {
      _llama = Llama(
        modelPath,
        contextParams: ContextParams()
          ..nCtx = 2048
          ..nThreads = 4
          ..nBatch = 512,
        verbose: false,
      );
      _isLoaded = true;
      print('✅ LlamaRuntimeService initialized');
    } catch (e) {
      throw Exception('Llama runtime initialization failed: $e');
    }
  }

  Future<String> generate(String prompt) async {
    if (!_isLoaded || _llama == null) {
      throw Exception('Llama runtime not initialized');
    }

    final buffer = StringBuffer();
    _llama!.setPrompt(prompt);

    await for (final token in _llama!.generateText()) {
      buffer.write(token);

      final text = buffer.toString();
      final first = text.indexOf('{');
      final last = text.lastIndexOf('}');

      if (first != -1 && last > first) {
        break; // Stop when JSON is closed
      }
    }

    return buffer.toString();
  }

  void dispose() {
    _llama?.dispose();
    _llama = null;
    _isLoaded = false;
  }
}
