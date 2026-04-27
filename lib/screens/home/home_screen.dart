import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OfflineMedic"),
        backgroundColor: const Color(0xFF1A4A7A),
      ),
      body: const Center(
        child: Text(
          "Home Screen",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}