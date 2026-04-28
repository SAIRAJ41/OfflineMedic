import 'package:flutter/material.dart';

class DrugCheckerScreen extends StatelessWidget {
  const DrugCheckerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [

            /// 🔵 HEADER STRIP + BACK BUTTON
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1F4A75),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Drug Checker",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
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

            /// BODY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    /// 🔝 TOP CONTENT GROUPED
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        /// TITLE
                        const Text(
                          "Drug Checker",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "OpenFDA database — offline",
                          style: TextStyle(color: Colors.white54),
                        ),

                        const SizedBox(height: 20),

                        /// 📦 SCANNED DRUG CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF112240),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "📷 Scanned from label",
                                style: TextStyle(color: Colors.white54),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Metformin 500mg + Ibuprofen 400mg",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// 🔄 PROCESSING STATUS
                        // TODO (TEAMMATE - AI ENGINE):
// Replace static text with actual AI output
// Input: scanned drugs / typed drugs
// Output:
// - interaction risk
// - explanation
// - severity
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 10),
                              SizedBox(width: 8),
                              Text(
                                "AI checking interactions...",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// ⚠️ INTERACTION FOUND
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "⚠ Interaction Found",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Ibuprofen may reduce Metformin effectiveness and increase kidney stress in diabetic patients.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// ✅ DOSAGE SAFE
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "✓ Dosage Check: Safe",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Both doses within WHO safe range for adult patient (60kg).",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// 🔻 PUSH CONTENT DOWN
                    const Spacer(),

                    /// 🔽 ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryBtn(
                            label: "Read",
                            icon: Icons.volume_up,
                            color: const Color(0xFF30D988),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryBtn(
                            label: "Save",
                            icon: Icons.save,
                            color: const Color(0xFF2E7DD1),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
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

/// 🔹 BUTTON
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}