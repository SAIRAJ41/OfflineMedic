import 'package:flutter/material.dart';
import '../processing/processing_screen.dart';

class CameraInputScreen extends StatelessWidget {
  const CameraInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Capture Image",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// CAMERA PREVIEW PLACEHOLDER
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF112240),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  "Camera Preview",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              // TODO (TEAMMATE):
              // Replace with CameraPreview (camera plugin)
            ),

            const SizedBox(height: 30),

            /// CAPTURE BUTTON
            GestureDetector(
              onTap: () {
                // TODO (TEAMMATE):
                // 1. Capture image
                // 2. Store / pass image
                // 3. Send to ProcessingScreen

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
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.camera, color: Colors.white, size: 28),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Tap to capture",
              style: TextStyle(color: Colors.white70),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}