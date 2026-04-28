import 'package:flutter/material.dart';
import '../processing/processing_screen.dart';

class TextInputScreen extends StatelessWidget {
  const TextInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Type Symptoms",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// INPUT BOX
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF112240),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Describe symptoms (e.g. fever, headache, nausea)",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),

                // TODO (TEAMMATE - INPUT CAPTURE):
                // Capture user-entered symptoms from controller.text
                // Pass this string to AI / rule engine
              ),

              const SizedBox(height: 10),

              /// EXAMPLE GUIDANCE (MEDICAL SAFE WORDING)
              const Text(
                "Example: fever for 2 days, headache, mild dizziness",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),

              /// SUBMIT BUTTON
              GestureDetector(
                onTap: () {
                  // TODO (TEAMMATE - PROCESSING PIPELINE):
                  // 1. Read input → controller.text
                  // 2. Validate / clean text
                  // 3. Send to AI model or backend
                  // 4. Receive structured result (severity, advice, etc.)

                  if (controller.text.trim().isEmpty) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProcessingScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7DD1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      "Analyze",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}