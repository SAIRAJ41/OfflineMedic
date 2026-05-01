import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int? expandedIndex;

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

  int countSeverity(String level) {
    return history.where((e) => e["severity"] == level).length;
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

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 🔷 DASHBOARD
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Overview",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _statBox("Total", history.length.toString(), Colors.blue),
                    const SizedBox(width: 10),
                    _statBox("Urgent",
                        countSeverity("URGENT").toString(), Colors.red),
                    const SizedBox(width: 10),
                    _statBox("Moderate",
                        countSeverity("MODERATE").toString(), Colors.orange),
                    const SizedBox(width: 10),
                    _statBox("Safe",
                        countSeverity("SAFE").toString(), Colors.green),
                  ],
                ),

                const SizedBox(height: 10),

                const Text(
                  "Tap a case to view details",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// 🔽 HISTORY LIST
          ...List.generate(history.length, (index) {
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
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// HEADER
                    Row(
                      children: [
                        const Icon(Icons.history),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item["title"],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          item["time"],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                    if (isExpanded) ...[
                      const SizedBox(height: 12),

                      /// 🔴 SEVERITY BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor(item["severity"])
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item["severity"],
                          style: TextStyle(
                            color: severityColor(item["severity"]),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// CONDITION
                      Text(item["condition"]),

                      const SizedBox(height: 10),

                      const Divider(height: 16),

                      /// DO NOW
                      ...List.generate(
                        item["do_now"].length,
                        (i) => Text("• ${item["do_now"][i]}"),
                      ),

                      /// TODO (TEAMMATE):
                      /// Replace with database_service.dart
                      /// Add:
                      /// - do_not
                      /// - red_flags
                      /// - confidence
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}