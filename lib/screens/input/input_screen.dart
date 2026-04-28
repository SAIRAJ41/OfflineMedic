import 'package:flutter/material.dart';
import '../triage/triage_screen.dart';

const _bgDeep = Color(0xFF0A1628);
const _card = Color(0xFF112240);

const _blue = Color(0xFF2E7DD1);
const _green = Color(0xFF30D988);
const _purple = Color(0xFF9B5DE5);

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  String selectedLang = "English";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 14),

              /// HEADER
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "New Assessment",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Choose input method",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// CONTEXT
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.health_and_safety, color: Colors.white70),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Select how you want to assess the patient",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

             /// OPTIONS
_InputCard(
  icon: Icons.camera_alt,
  title: "Photograph",
  subtitle: "Scan wound / medicine",
  color: _blue,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TriageScreen(severity: Severity.urgent),
      ),
    );
  },
),

const SizedBox(height: 12),

_InputCard(
  icon: Icons.mic,
  title: "Speak Symptoms",
  subtitle: "English/Hindi/Marathi",
  color: _green,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TriageScreen(severity: Severity.moderate),
      ),
    );
  },
),

const SizedBox(height: 12),

_InputCard(
  icon: Icons.edit,
  title: "Type Symptoms",
  subtitle: "Manual Input",
  color: _purple,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TriageScreen(severity: Severity.safe),
      ),
    );
  },
),

              const Spacer(),

              /// LANGUAGE SELECTOR
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LangChip(
                      label: "English",
                      active: selectedLang == "English",
                      onTap: () => setState(() => selectedLang = "English"),
                    ),
                    const SizedBox(width: 8),
                    _LangChip(
                      label: "हिंदी",
                      active: selectedLang == "हिंदी",
                      onTap: () => setState(() => selectedLang = "हिंदी"),
                    ),
                    const SizedBox(width: 8),
                    _LangChip(
                      label: "मराठी",
                      active: selectedLang == "मराठी",
                      onTap: () => setState(() => selectedLang = "मराठी"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INPUT CARD
// ─────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _InputCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container( // ✅ FIX: use Container instead of Ink
          constraints: const BoxConstraints(
            minHeight: 90, // 👈 bigger cards
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LANGUAGE CHIP
// ─────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _blue : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}