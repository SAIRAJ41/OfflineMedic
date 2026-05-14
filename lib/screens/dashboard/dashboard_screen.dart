import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// TODO: Re-enable PDF export after hackathon.
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';


import '../../services/database_service.dart';
import '../../services/ai_test_service.dart';
import '../../models/case_history.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedPieIndex = -1;
  bool _isLoading = true;

  // --- DATA (loaded from SQLite) ---
  Map<String, int> summary = {'total': 0, 'urgent': 0, 'moderate': 0, 'mild': 0};
  List<double> weekly = List.filled(7, 0);
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<CaseHistory> recentCases = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final s = await DatabaseService.instance.getDashboardSummary();
      final w = await DatabaseService.instance.getWeeklyCounts();
      final c = await DatabaseService.instance.getCases(limit: 5);

      if (mounted) {
        setState(() {
          summary = s;
          weekly = w;
          recentCases = c;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Map day-of-week labels starting from 6 days ago.
  List<String> get _weekLabels {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return dayNames[d.weekday - 1];
    });
  }

  /* TODO: Re-enable PDF export after hackathon.
  Future<void> exportReport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating professional report...'),
      ),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('OfflineMedic',
                style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800)),
            pw.SizedBox(height: 6),
            pw.Text('Weekly Triage & Operations Report',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey700,
                )),
            pw.Divider(thickness: 2, color: PdfColors.blue200),
            pw.SizedBox(height: 20),
            pw.Text('Executive Summary',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfStatBox(
                    'Total Cases', '${summary['total']}', PdfColors.blue),
                _buildPdfStatBox(
                    'Urgent', '${summary['urgent']}', PdfColors.red),
                _buildPdfStatBox(
                    'Moderate', '${summary['moderate']}', PdfColors.orange),
                _buildPdfStatBox('Mild', '${summary['mild']}', PdfColors.green),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Text('Recent Patient Logs',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (recentCases.isNotEmpty)
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue100),
                headerHeight: 28,
                cellHeight: 34,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                },
                headers: [
                  'Condition',
                  'Status',
                  'Time Logged',
                  'Immediate Action Required',
                ],
                data: recentCases
                    .map((c) => [
                          c.result.condition,
                          c.result.triageLevel,
                          _timeAgo(c.createdAt),
                          c.result.doNow.isNotEmpty
                              ? c.result.doNow.first
                              : '-',
                        ])
                    .toList(),
              ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'OfflineMedic_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  pw.Widget _buildPdfStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 98,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final weekLabels = _weekLabels;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // TODO: Re-enable PDF export after hackathon.
          /*
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.blue),
            tooltip: 'Export Report',
            onPressed: () => exportReport(context),
          ),
          */
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard('Total', summary['total'].toString(),
                          Colors.blue, Icons.people_alt),
                      const SizedBox(width: 12),
                      _buildStatCard('Urgent', summary['urgent'].toString(),
                          Colors.red, Icons.warning_rounded),
                      const SizedBox(width: 12),
                      _buildStatCard(
                          'Moderate',
                          summary['moderate'].toString(),
                          Colors.orange,
                          Icons.healing),
                      const SizedBox(width: 12),
                      _buildStatCard('Mild', summary['mild'].toString(),
                          Colors.green, Icons.check_circle),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analytics Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        const Text(
                          'Triage Distribution',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                            height: 220, child: _buildInteractivePieChart()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cases This Week',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                            height: 200,
                            child: _buildPremiumBarChart(weekLabels)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Patient Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  if (recentCases.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: _cardDecoration(),
                      child: const Column(
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No cases recorded yet',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Assessments will appear here after triage',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: recentCases
                          .map((c) => _ExpandableCaseCard(caseData: c))
                          .toList(),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, MaterialColor color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.shade600, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractivePieChart() {
    final urgent = (summary['urgent'] ?? 0).toDouble();
    final moderate = (summary['moderate'] ?? 0).toDouble();
    final mild = (summary['mild'] ?? 0).toDouble();

    if (urgent == 0 && moderate == 0 && mild == 0) {
      return const Center(
        child: Text('No data yet',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedPieIndex = -1;
                return;
              }
              _touchedPieIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: [
          _buildPieSection(0, urgent, Colors.red, 'Urgent'),
          _buildPieSection(1, moderate, Colors.orange, 'Moderate'),
          _buildPieSection(2, mild, Colors.green, 'Mild'),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(
      int index, double value, Color color, String title) {
    final isTouched = index == _touchedPieIndex;
    final radius = isTouched ? 65.0 : 55.0;
    final fontSize = isTouched ? 16.0 : 14.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: isTouched ? '$title\n${value.toInt()}' : value.toInt().toString(),
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      badgeWidget: isTouched ? null : _buildBadge(title, color),
      badgePositionPercentageOffset: 1.2,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPremiumBarChart(List<String> weekLabels) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (weekly.reduce((a, b) => a > b ? a : b) + 3).ceilToDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= weekLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    weekLabels[idx],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          weekly.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: weekly[i],
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (weekly.reduce((a, b) => a > b ? a : b) + 3)
                      .ceilToDouble(),
                  color: Colors.blue.shade50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDrawer(BuildContext context) {
    final passRate = AiTestService.instance.getPassRate();

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety,
                    color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'OfflineMedic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.white70),
                ),
                if (passRate != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI: $passRate ✓',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_document),
            title: const Text('Input Triage'),
            onTap: () => Navigator.pushReplacementNamed(context, '/input'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blue),
            title: const Text(
              'Dashboard',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            tileColor: Colors.blue.shade50,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Offline Map'),
            onTap: () => Navigator.pushReplacementNamed(context, '/map'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

// ══════════════════════════════════════════════════════════════
//  Expandable case card — built from CaseHistory
// ══════════════════════════════════════════════════════════════

class _ExpandableCaseCard extends StatefulWidget {
  final CaseHistory caseData;
  const _ExpandableCaseCard({required this.caseData});

  @override
  State<_ExpandableCaseCard> createState() => _ExpandableCaseCardState();
}

class _ExpandableCaseCardState extends State<_ExpandableCaseCard>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      expanded = !expanded;
      expanded ? _controller.forward() : _controller.reverse();
    });
  }

  Color get _statusColor {
    switch (widget.caseData.result.triageLevel) {
      case 'URGENT':
        return Colors.red;
      case 'MODERATE':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.caseData;
    final statusColor = _statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 5)),
          ),
          child: InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.result.triageLevel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.result.condition,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(c.createdAt),
                        style:
                            TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      RotationTransition(
                        turns: _iconTurns,
                        child: Icon(Icons.expand_more,
                            color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild:
                        const SizedBox(height: 0, width: double.infinity),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        Text(
                          'Input:',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(c.inputText,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        if (c.result.doNow.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.assignment_late,
                                        size: 16, color: Colors.blue),
                                    SizedBox(width: 6),
                                    Text(
                                      'Immediate Actions:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...(c.result.doNow.map<Widget>(
                                    (e) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '• ',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  e,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))),
                              ],
                            ),
                          ),
                      ],
                    ),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
