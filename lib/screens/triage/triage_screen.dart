import 'package:flutter/material.dart';
import '../emergency/emergency_screen.dart';
import '../drug/drug_checker_screen.dart';
import '../facilities/offline_map_screen.dart';

const _bgDeep = Color(0xFF0A1628);
const _card = Color(0xFF112240);

const _red = Color(0xFFFF4545);
const _yellow = Color(0xFFFFB830);
const _green = Color(0xFF30D988);

enum Severity { urgent, moderate, safe }

class TriageScreen extends StatelessWidget {
  final Severity severity;

  const TriageScreen({super.key, required this.severity});

  Color get color {
    switch (severity) {
      case Severity.urgent:
        return _red;
      case Severity.moderate:
        return _yellow;
      case Severity.safe:
        return _green;
    }
  }

  String get title {
    switch (severity) {
      case Severity.urgent:
        return "URGENT";
      case Severity.moderate:
        return "MODERATE";
      case Severity.safe:
        return "SAFE";
    }
  }

  String get action {
    switch (severity) {
      case Severity.urgent:
        return "Go to nearest hospital immediately";
      case Severity.moderate:
        return "Consult a doctor soon";
      case Severity.safe:
        return "Safe for home care";
    }
  }

  List<String> get careTips {
    switch (severity) {
      case Severity.urgent:
        return [
          "Keep patient stable",
          "Avoid delay",
          "Seek medical help immediately"
        ];
      case Severity.moderate:
        return [
          "Monitor symptoms",
          "Stay hydrated",
          "Take proper rest"
        ];
      case Severity.safe:
        return [
          "Basic first aid",
          "Clean affected area",
          "Stay hydrated"
        ];
    }
  }

  String get explanation {
    switch (severity) {
      case Severity.urgent:
        return "Symptoms indicate potential serious condition requiring immediate medical attention.";
      case Severity.moderate:
        return "Condition is not critical but should be checked by a doctor soon.";
      case Severity.safe:
        return "No serious symptoms detected. Condition can be managed at home.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [

              const SizedBox(height: 16),

              /// HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Assessment Result",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// SEVERITY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      severity == Severity.urgent
                          ? Icons.warning
                          : severity == Severity.moderate
                              ? Icons.info
                              : Icons.check_circle,
                      color: color,
                      size: 55,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// CARE TIPS
              _SectionCard(
                title: "Care Tips",
                children: careTips
                    .map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text("• $tip",
                              style: const TextStyle(color: Colors.white70)),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 14),

              /// RECOMMENDATION
              _SectionCard(
                title: "Recommendation",
                children: [
                  Text(action,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),

              const SizedBox(height: 55),

              /// AI EXPLANATION
              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0xFFFFB830).withOpacity(0.15),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: const Color(0xFFFFB830).withOpacity(0.4),
    ),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.psychology, color: Color(0xFFFFB830)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Analysis",
              style: TextStyle(
                color: Color(0xFFFFB830),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              explanation,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    ],
  ),
),
const SizedBox(height: 18),

Row(
  children: [
    Expanded(
      child: _MiniAction(
        label: "Emergency",
        icon: Icons.call,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EmergencyScreen(),
            ),
          );
        },
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _MiniAction(
        label: "Drugs",
        icon: Icons.medication,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DrugCheckerScreen(),
            ),
          );
        },
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _MiniAction(
        label: "Map",
        icon: Icons.map,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OfflineMapScreen(),
            ),
          );
        },
      ),
    ),
  ],
),
              const Spacer(),

              /// CTA BUTTON
              _PrimaryButton(
                label: "Start New Assessment",
                icon: Icons.refresh,
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// SECTION CARD
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

/// PRIMARY BUTTON (FIXED)
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D5FA3), Color(0xFF2E7DD1)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7DD1).withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

