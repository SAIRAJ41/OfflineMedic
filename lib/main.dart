import 'package:flutter/material.dart';
import 'screens/input/input_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/map/map_screen.dart';
import 'services/database_service.dart';
import 'services/gemma_service.dart';
import 'services/voice_input_service.dart';
import 'services/ai_test_service.dart';

void main() async {
  // ← must be async and must call this first
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Database first (other services may depend on it)
  await DatabaseService.instance.initialize();

  // 2. Gemma second (reads system prompt from assets)
  await GemmaService.instance.initialize();

  // 3. Voice last (independent, no DB dependency)
  await VoiceInputService.instance.initialize();

  // 4. Load AI test results (non-blocking, for drawer badge)
  await AiTestService.instance.load();

  runApp(const OfflineMedicApp());
}

class OfflineMedicApp extends StatelessWidget {
  const OfflineMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OfflineMedic',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/input': (context) => const InputScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/map': (context) => const MapScreen(),
      },
      home: const InputScreen(),
    );
  }
}
