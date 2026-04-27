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
        scaffoldBackgroundColor: const Color(0xFF0A1628),
      ),
      home: const HomeScreen(),
    );
  }
}