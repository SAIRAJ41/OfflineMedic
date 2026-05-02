import 'package:flutter/material.dart';
import '../../services/gemma_service.dart';
import '../../models/triage_result.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController controller = TextEditingController();

  bool isLoading = false;
  TriageResult? result;
  int selectedInput = 2;

  void analyze() async {
    if (controller.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    final res = await GemmaService.analyze(controller.text);

    /// ✅ AUTO SAVE TRIGGER
    /// TODO (TEAMMATE - DATABASE):
    /// Save case automatically after analysis

    setState(() {
      result = res;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _drawer(context),

      body: SafeArea(
        child: Builder(
          builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// HEADER (UNCHANGED)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),

                    const Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                    ),

                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 28),

                /// 🔥 FIXED BUTTON ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _inputCard(0, Icons.upload_file, "Upload", "Upload image"),
                    _inputCard(1, Icons.mic, "Speak", "Tap to record"),
                    _inputCard(2, Icons.keyboard, "Type", "Enter symptoms"),
                  ],
                ),

                const SizedBox(height: 28),

                if (selectedInput == 2) _inputBox(),
                if (selectedInput == 1)
                  _placeholder("Voice input will appear here"),
                if (selectedInput == 0)
                  _placeholder("Image upload preview here"),

                const SizedBox(height: 28),

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
                  _resultCard(),
                  const SizedBox(height: 24),

                  if (result!.callNow)
                    Container(
                      height: 72,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6152E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          "CALL EMERGENCY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputBox() {
    return Container(
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
    );
  }

  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result!.triageLevel,
              style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),
          Text(result!.condition),

          const SizedBox(height: 12),
          const Text("Do Now:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...result!.doNow.map((e) => Text("• $e")),

          const SizedBox(height: 10),
          const Text("Do NOT:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...result!.doNot.map((e) => Text("• $e")),

          const SizedBox(height: 10),
          const Text("Red Flags:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...result!.redFlags.map((e) => Text("⚠ $e")),
        ],
      ),
    );
  }

  Widget _placeholder(String text) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC2C6D4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text(text)),
    );
  }

  static Widget _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("OfflineMedic",
                style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            title: const Text("Input"),
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/input'),
          ),
          ListTile(
            title: const Text("Dashboard"),
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            title: const Text("Map"),
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/map'),
          ),
        ],
      ),
    );
  }

  /// 🔥 FIXED SQUARE BUTTONS
  Widget _inputCard(int index, IconData icon, String title, String subtitle) {
    final isActive = selectedInput == index;

    return GestureDetector(
      onTap: () => setState(() => selectedInput = index),
      child: Column(
        children: [
          Container(
            height: 100,
            width: 100,
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
              color: isActive ? Colors.white : Colors.blue,
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
    );
  }
}