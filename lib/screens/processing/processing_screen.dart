import 'dart:async';
import 'package:flutter/material.dart';
import '../triage/triage_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int step = 0;

  final List<String> steps = [
    "Analyzing...",
    "Generating result...",
  ];

  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (step < steps.length - 1) {
        setState(() => step++);
      } else {
        t.cancel();

        /// 🛑 IMPORTANT: avoid crash if widget disposed
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TriageScreen(
              severity: Severity.moderate,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// 🔄 LOADER (slightly bigger = better feel)
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),

            const SizedBox(height: 28),

            /// 🧠 STEP TEXT
            Text(
              steps[step],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Running locally • No internet",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}