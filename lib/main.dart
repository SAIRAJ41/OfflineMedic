import 'package:flutter/material.dart';
import 'screens/input/input_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'services/database_service.dart';
import 'services/gemma_service.dart';
import 'services/voice_input_service.dart';
import 'services/ai_test_service.dart';
import 'services/model_download_service.dart';

void main() async {
  // ← must be async and must call this first
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Database first (other services may depend on it)
  await DatabaseService.instance.initialize();

  // 2. Voice (independent, no DB dependency)
  await VoiceInputService.instance.initialize();

  // 3. Load AI test results (non-blocking, for drawer badge)
  await AiTestService.instance.load();

  // 4. Check if model is downloaded
  final modelDownloaded = await ModelDownloadService.instance.isModelDownloaded();

  if (modelDownloaded) {
    // Fire and forget — do not block app startup.
    // InputScreen will show "Loading AI Model..." and handle the loading state.
    GemmaService.instance.initialize();
  }

  runApp(OfflineMedicApp(modelDownloaded: modelDownloaded));
}

class OfflineMedicApp extends StatelessWidget {
  final bool modelDownloaded;

  const OfflineMedicApp({super.key, required this.modelDownloaded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OfflineMedic',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/input': (context) => const InputScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/map': (context) => const MapScreen(),
      },
      home: modelDownloaded ? const InputScreen() : const SetupScreen(),
    );
  }
}
