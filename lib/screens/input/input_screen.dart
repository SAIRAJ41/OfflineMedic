import 'package:flutter/material.dart';
import '../../services/gemma_service.dart';
import '../../models/triage_result.dart';
import '../map/map_screen.dart';
import '../home/home_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController controller = TextEditingController();

  bool isLoading = false;
  TriageResult? result;
  int selectedInput = 2; // 0=upload, 1=speak, 2=type

  void analyze() async {
    if (controller.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    final res = await GemmaService.analyze(controller.text);

    setState(() {
      result = res;
      isLoading = false;
    });

    /// TODO (TEAMMATE):
    /// Combine:
    /// - Text input
    /// - Voice (Whisper → voice_service.dart)
    /// - Image (camera)
  }

  Color severityColor(String level) {
    switch (level) {
      case "URGENT":
        return Colors.red;
      case "MODERATE":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medical_services, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Medical Assistant",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// INPUT OPTIONS 
              Row(
                children: [
                  _inputCard(0, Icons.upload_file, "Upload", "Upload image"),
                  const SizedBox(width: 12),
                  _inputCard(1, Icons.mic, "Speak", "Tap to record"),
                  const SizedBox(width: 12),
                  _inputCard(2, Icons.keyboard, "Type", "Enter symptoms"),
                ],
              ),

              const SizedBox(height: 28),

              /// 🔁 SWITCHED CONTENT BASED ON MODE

              if (selectedInput == 2) ...[
                /// TYPE MODE
                const Text(
                  "CURRENT DESCRIPTION",
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Color(0xFF727784),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFC2C6D4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: "Enter symptoms...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(18),
                    ),
                  ),
                ),
              ],

              if (selectedInput == 1) ...[
                /// SPEAK MODE (MOCK UI)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFC2C6D4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text("Voice input will appear here"),
                  ),
                ),

                /// TODO (TEAMMATE):
                /// Integrate Whisper here
              ],

              if (selectedInput == 0) ...[
                /// UPLOAD MODE (MOCK UI)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFC2C6D4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text("Image upload preview here"),
                  ),
                ),

                /// TODO (TEAMMATE):
                /// Integrate camera/gallery here
              ],

              const SizedBox(height: 28),

              /// ANALYZE BUTTON
              GestureDetector(
                onTap: isLoading ? null : analyze,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF003F87),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      "Analyze Now",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              if (isLoading)
                const Center(child: Text("Analyzing...")),

              if (result != null && !isLoading) ...[

                /// RESULT
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Severity: ${result!.triageLevel}"),
                      const SizedBox(height: 8),
                      Text(result!.condition),
                      const SizedBox(height: 8),
                      ...result!.doNow.map((e) => Text("• $e")),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🚨 STATIC EMERGENCY BUTTON 
                if (result!.callNow)
                  Container(
                    height: 78,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB6152E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        "Call Emergency",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                /// ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapScreen(),
                              ),
                            );
                          },
                          child: const Text("Nearby"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text("Save"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _inputCard(int index, IconData icon, String title, String subtitle) {
    final isActive = selectedInput == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedInput = index);
        },
        child: Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF003F87)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(
                icon,
                size: 28,
                color:
                    isActive ? Colors.white : const Color(0xFF003F87),
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}