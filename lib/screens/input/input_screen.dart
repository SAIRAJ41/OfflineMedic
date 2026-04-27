import 'package:flutter/material.dart';

class InputScreen extends StatelessWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: Text("Input Screen", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}