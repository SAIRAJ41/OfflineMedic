import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedPieIndex = -1;

  // --- MOCK DATA ---
  final Map<String, int> summary = {
    'total': 47,
    'urgent': 12,
    'moderate': 18,
    'mild': 17,
  };

  final List<double> weekly = [5, 8, 3, 7, 6, 12, 6];
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<Map<String, dynamic>> recentCases = [
    {
      'title': 'Dengue fever',
      'time': '2 hr ago',
      'level': 'Urgent',
      'color': Colors.red,
      'condition': 'Suspected dengue with high fever and rash.',
      'do_now': [
        'Administer IV fluids',
        'Monitor fever closely',
        'Check platelet count',
      ],
    },
    {
      'title': 'Severe Burns',
      'time': '6 hr ago',
      'level': 'Moderate',
      'color': Colors.orange,
      'condition': 'Second degree burn on left forearm.',
      'do_now': [
        'Apply cool water',
        'Cover with sterile dressing',
        'Administer pain relief',
      ],
    },
    {
      'title': 'Viral Cold',
      'time': 'Yesterday',
      'level': 'Mild',
      'color': Colors.green,
      'condition': 'Upper respiratory tract infection.',
      'do_now': ['Rest', 'Hydrate', 'Prescribe mild antipyretic'],
    },
  ];

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
                        c['title'],
                        c['level'],
                        c['time'],
                        (c['do_now'] as List).first.toString(),
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

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.blue),
            tooltip: 'Export Report',
            onPressed: () => exportReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                _buildStatCard('Moderate', summary['moderate'].toString(),
                    Colors.orange, Icons.healing),
                const SizedBox(width: 12),
                _buildStatCard('Mild', summary['mild'].toString(), Colors.green,
                    Icons.check_circle),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: 220, child: _buildInteractivePieChart()),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(height: 200, child: _buildPremiumBarChart()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Patient Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Column(
              children:
                  recentCases.map((c) => ExpandableCase(data: c)).toList(),
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
          _buildPieSection(0, 12, Colors.red, 'Urgent'),
          _buildPieSection(1, 18, Colors.orange, 'Moderate'),
          _buildPieSection(2, 17, Colors.green, 'Mild'),
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

  Widget _buildPremiumBarChart() {
    // IMPORTANT: fl_chart 0.68.0 does not support the newer tooltip named params used earlier.
    // Keep this simple to guarantee compilation.
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 15,
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
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt()],
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
                  toY: 15,
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'OfflineMedic',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.white70),
                ),
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
}

class ExpandableCase extends StatefulWidget {
  final Map<String, dynamic> data;
  const ExpandableCase({super.key, required this.data});

  @override
  State<ExpandableCase> createState() => _ExpandableCaseState();
}

class _ExpandableCaseState extends State<ExpandableCase>
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

  @override
  Widget build(BuildContext context) {
    final Color statusColor = widget.data['color'] as Color;

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
                          widget.data['level'].toString(),
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
                          widget.data['title'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        widget.data['time'].toString(),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
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
                          'Notes:',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.data['condition'].toString(),
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
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
                              ...((widget.data['do_now'] as List)
                                  .map<Widget>((e) => Padding(
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
                                                e.toString(),
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
