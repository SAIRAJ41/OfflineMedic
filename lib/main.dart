import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';

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
        brightness: Brightness.dark,
        useMaterial3: true, // 🔥 modern UI feel (important)

        scaffoldBackgroundColor: const Color(0xFF0A1628),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2E7DD1),
          surface: Color(0xFF112240),
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
      ),

      home: const HomeDashboard(data: dummyDashboardData),
    );
  }
}