import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [

            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF8B1E1E),
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
                    "Emergency",
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
                      color: Colors.redAccent,
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

                    /// 🔝 TOP CONTENT
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        const SizedBox(height: 10),

                        const Text(
                          "GSM call — no data needed",
                          style: TextStyle(color: Colors.white54),
                        ),

                        const SizedBox(height: 22),

                        /// 🚨 CALL CARD
                        GestureDetector(
                          onTap: () {
                            // TODO (TEAMMATE - CALL INTEGRATION):
                            // Use url_launcher to trigger emergency call
                            // Example:
                            // launchUrl(Uri.parse("tel:108"));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.call,
                                    size: 34, color: Colors.white),
                                SizedBox(height: 10),
                                Text(
                                  "108",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Tap to call ambulance — India",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        /// 🧾 AUTO BRIEF BOX
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF112240),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Text(
                            "Emergency: Patient, 45 yr male, severe fever.\n"
                            "Location auto-detected.\n"
                            "Condition: Conscious but weak.",
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                   
                    const Spacer(),

                    
                    Column(
                      children: [

                        const Text(
                          "No call signal?",
                          style: TextStyle(color: Colors.white54),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _SecondaryButton(
                                label: "SMS location",
                                onTap: () {
                                  // TODO (TEAMMATE - SMS INTEGRATION):
                      // Use url_launcher:
                      // launchUrl(Uri.parse("sms:<number>?body=<message>"))
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SecondaryButton(
                                label: "Alert contact",
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        const Center(
                          child: Text(
                            "GPS coords auto-attached to SMS",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
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

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1D5FA3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}