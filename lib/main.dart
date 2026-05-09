import 'package:flutter/material.dart';
import 'screens/input/input_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/map/map_screen.dart';

void main() {
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
