import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'screens/input/input_screen.dart';
import 'screens/map/map_screen_new.dart';
import 'screens/setup/setup_screen.dart';
import 'services/ai_test_service.dart';
import 'services/database_service.dart';
import 'services/gemma_service.dart';
import 'services/model_download_service.dart';
import 'services/voice_input_service.dart';

/// `true` = open map immediately (no model / setup / download gate).
/// `false` = original flow: setup until model exists, then input home.
const bool kMapFirstMode = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.initialize();
  await VoiceInputService.instance.initialize();

  await AiTestService.instance.load();

  var modelDownloaded = false;
  if (!kMapFirstMode) {
    modelDownloaded = await ModelDownloadService.instance.isModelDownloaded();
    if (modelDownloaded) {
      await GemmaService.instance.initialize();
    }
  }

  runApp(OfflineMedicApp(
    mapFirst: kMapFirstMode,
    modelDownloaded: modelDownloaded,
  ));
}

class OfflineMedicApp extends StatelessWidget {
  final bool mapFirst;
  final bool modelDownloaded;

  const OfflineMedicApp({
    super.key,
    required this.mapFirst,
    required this.modelDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (mapFirst) {
      home = const MapScreenNew();
    } else if (modelDownloaded) {
      home = const InputScreen();
    } else {
      home = const SetupScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OfflineMedic',
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/input': (context) => const InputScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/map': (context) => const MapScreenNew(),
      },
      home: home,
    );
  }
}
