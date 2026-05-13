import 'package:flutter/material.dart';
import '../../models/triage_result.dart';
import 'package:flutter/foundation.dart';

class TriageScreen extends StatelessWidget {
  final TriageResult result;

  const TriageScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Result'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Triage Level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getColor(result.triageColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.triageLevel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Condition Summary
            const Text(
              "Condition Summary:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(result.condition),
            const SizedBox(height: 24),

            // Do Now
            if (result.doNow.isNotEmpty) ...[
              const Text(
                "Do Now (Immediate Action):",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              ...result.doNow.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Do Not
            if (result.doNot.isNotEmpty) ...[
              const Text(
                "DO NOT do this:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 8),
              ...result.doNot.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("❌ ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Red Flags
            if (result.redFlags.isNotEmpty) ...[
              const Text(
                "Watch out for Red Flags:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
              ),
              const SizedBox(height: 8),
              ...result.redFlags.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⚠️ ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Emergency
            if (result.callNow) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "EMERGENCY - CALL ${result.emergencyNumber}",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (result.dispatcherScript.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text("What to tell the dispatcher:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(result.dispatcherScript, textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Disclaimer
            const Divider(),
            const SizedBox(height: 8),
            Text(
              result.disclaimer,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            
            // Raw Response (DEBUG ONLY)
            if (kDebugMode) ...[
              const SizedBox(height: 32),
              const Text(
                "RAW RESPONSE (DEBUG ONLY)",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: SelectableText(result.rawResponse),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF$hex";
    }
    return Color(int.parse(hex, radix: 16));
  }
}
