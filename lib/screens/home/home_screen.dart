import 'package:flutter/material.dart';
import '../input/input_screen.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

enum TriageStatus { urgent, moderate, safe }

class CaseItem {
  final String title;
  final String timeAgo;
  final TriageStatus status;

  const CaseItem({
    required this.title,
    required this.timeAgo,
    required this.status,
  });
}

class DashboardData {
  final String workerName;
  final int casesToday;
  final int urgentCases;
  final List<CaseItem> recentCases;

  const DashboardData({
    required this.workerName,
    required this.casesToday,
    required this.urgentCases,
    required this.recentCases,
  });
}

// ─────────────────────────────────────────────
// DUMMY DATA
// ─────────────────────────────────────────────

const dummyDashboardData = DashboardData(
  workerName: 'Priya Sharma',
  casesToday: 12,
  urgentCases: 3,
  recentCases: [
    CaseItem(title: 'Wound Infection', timeAgo: '8 min ago', status: TriageStatus.urgent),
    CaseItem(title: 'Fever & Chills', timeAgo: '42 min ago', status: TriageStatus.moderate),
    CaseItem(title: 'Minor Bruising', timeAgo: '1 hr ago', status: TriageStatus.safe),
  ],
);

// ─────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────

const _bgDeep = Color(0xFF0A1628);
const _bgCard = Color(0xFF112240);
const _bgCardAlt = Color(0xFF0D1B35);
const _accent = Color(0xFF2E7DD1);
const _urgent = Color(0xFFFF4545);
const _moderate = Color(0xFFFFB830);
const _safe = Color(0xFF30D988);
const _textPri = Color(0xFFEEF2FF);
const _textSec = Color(0xFF8899BB);
const _offlineBg = Color(0xFF0F2040);

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────

void main() {
  runApp(const OfflineMedicApp());
}

class OfflineMedicApp extends StatelessWidget {
  const OfflineMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OfflineMedic',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bgDeep,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: _accent,
          surface: _bgCard,
        ),
      ),
      home: const HomeDashboard(data: dummyDashboardData),
    );
  }
}

// ─────────────────────────────────────────────
// HOME DASHBOARD
// ─────────────────────────────────────────────

class HomeDashboard extends StatelessWidget {
  final DashboardData data;
  const HomeDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _Header(workerName: data.workerName),

              const SizedBox(height: 26),

              const _DashboardTitle(),

              const SizedBox(height: 22),

              /// STATS
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Cases Today',
                      value: data.casesToday.toString(),
                      icon: Icons.assignment_outlined,
                      iconColor: _accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      label: 'Urgent Cases',
                      value: data.urgentCases.toString(),
                      icon: Icons.warning_amber_rounded,
                      iconColor: _urgent,
                      highlight: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const _AiStatusBadge(),

              const SizedBox(height: 22),

              const Text(
                'Recent Cases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                ),
              ),

              const SizedBox(height: 12),

              ...data.recentCases.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CaseListItem(caseItem: c),
                ),
              ),

              const Spacer(),

              _PrimaryButton(
  label: 'Start New Assessment',
  icon: Icons.add_circle_outline_rounded,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InputScreen(),
      ),
    );
  },
),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String workerName;
  const _Header({required this.workerName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_hospital, color: _accent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'OfflineMedic',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textPri,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _offlineBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'OFFLINE',
            style: TextStyle(
              color: _safe,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TITLE
// ─────────────────────────────────────────────

class _DashboardTitle extends StatelessWidget {
  const _DashboardTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _textPri,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Community Health Worker',
          style: TextStyle(color: _textSec),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool highlight;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlight ? _urgent.withOpacity(0.18) : _bgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textPri,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _textSec)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AI STATUS
// ─────────────────────────────────────────────

class _AiStatusBadge extends StatelessWidget {
  const _AiStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _safe.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.psychology, color: _safe),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "AI running locally • No internet needed",
              style: TextStyle(color: _textPri),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CASE ITEM
// ─────────────────────────────────────────────

class CaseListItem extends StatelessWidget {
  final CaseItem caseItem;
  const CaseListItem({super.key, required this.caseItem});

  Color get color {
    switch (caseItem.status) {
      case TriageStatus.urgent:
        return _urgent;
      case TriageStatus.moderate:
        return _moderate;
      case TriageStatus.safe:
        return _safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caseItem.title, style: const TextStyle(color: _textPri)),
                const SizedBox(height: 2),
                Text(caseItem.timeAgo, style: const TextStyle(color: _textSec)),
              ],
            ),
          ),
          Text(
            caseItem.status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CTA BUTTON
// ─────────────────────────────────────────────

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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: Ink(
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5FA3), Color(0xFF2E7DD1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.5),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}