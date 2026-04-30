import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  /// Track which card is expanded
  int? expandedIndex;

  /// 🔹 MOCK DATA (replace later)
  final List<Map<String, dynamic>> history = [
    {
      "title": "Wound Infection",
      "time": "8 min ago • URGENT",
      "severity": "URGENT",
      "condition": "Possible infected wound with swelling",
      "do_now": [
        "Clean with water",
        "Apply antiseptic",
        "Keep area dry"
      ]
    },
    {
      "title": "Fever & Chills",
      "time": "42 min ago • MODERATE",
      "severity": "MODERATE",
      "condition": "Likely viral fever",
      "do_now": [
        "Take paracetamol",
        "Stay hydrated",
        "Rest"
      ]
    },
    {
      "title": "Minor Bruising",
      "time": "1 hr ago • SAFE",
      "severity": "SAFE",
      "condition": "Soft tissue injury",
      "do_now": [
        "Apply cold compress",
        "Rest area",
        "Avoid pressure"
      ]
    },
  ];

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

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "History",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final isExpanded = expandedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                expandedIndex = isExpanded ? null : index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER ROW
                  Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item["title"],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        item["time"],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  /// 🔽 EXPANDED CONTENT
                  if (isExpanded) ...[
                    const SizedBox(height: 12),

                    /// Severity
                    Row(
                      children: [
                        const Text("Severity: "),
                        Text(
                          item["severity"],
                          style: TextStyle(
                            color: severityColor(item["severity"]),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// Condition
                    Text(item["condition"]),

                    const SizedBox(height: 10),

                    /// Do Now
                    ...List.generate(
                      item["do_now"].length,
                      (i) => Text("• ${item["do_now"][i]}"),
                    ),

                    /// TODO (TEAMMATE - HISTORY DETAILS):
                    /// Replace mock data with:
                    /// database_service.dart stored reports
                    /// Show full JSON:
                    /// - do_not
                    /// - red_flags
                    /// - confidence
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}