import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../processing/processing_screen.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  List<double> bars = List.generate(8, (_) => 0.3);
  Timer? timer;

  @override
  void initState() {
    super.initState();

    /// 🔥 Fake waveform animation
    timer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      setState(() {
        bars = List.generate(
          8,
          (_) => 0.2 + Random().nextDouble(),
        );
      });
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
      body: SafeArea(
        child: Column(
          children: [

            /// 🔵 HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1F4A75),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("OfflineMedic",
                      style: TextStyle(color: Colors.white)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "OFFLINE",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [

                    const SizedBox(height: 10),

                    const Text(
                      "Listening...",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      "Whisper.cpp — local STT",
                      style: TextStyle(color: Colors.white54),
                    ),

                    const SizedBox(height: 28),

                    /// 🎤 WAVEFORM (ANIMATED)
                    Container(
                      height: 90,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF112240),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(bars.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 6,
                            height: 40 + (bars[i] * 40),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),

                    /// 🔧 TODO FOR TEAMMATE
                    /// Replace this animation with real mic amplitude stream

                    const SizedBox(height: 18),

                    const Text(
                      "बोलते रहें... (Keep speaking)",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// 🧾 TRANSCRIPTION BOX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF112240),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TRANSCRIBED",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "मुझे दो दिन से बुखार है, खांसी और थकान है...",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      // TODO (TEAMMATE):
                      // Replace with real-time Whisper transcription stream
                    ),

                    const SizedBox(height: 14),

                    /// 🔄 STATUS
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle,
                              color: Colors.greenAccent, size: 10),
                          SizedBox(width: 8),
                          Text(
                            "Sending to AI for analysis...",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    /// 🔴 STOP BUTTON
                    GestureDetector(
                     onTap: () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const ProcessingScreen(),
    ),
  );
},
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.stop,
                            color: Colors.black, size: 28),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Tap to stop",
                      style: TextStyle(color: Colors.redAccent),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}