import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> exportReport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating report...")),
    );

    final pdf = pw.Document();

    final recentCases = [
      {"title": "Dengue fever", "time": "2 hr ago", "level": "URGENT"},
      {"title": "Burns", "time": "6 hr ago", "level": "MODERATE"},
      {"title": "Cold", "time": "Yesterday", "level": "MILD"},
    ];

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("OfflineMedic Report",
                style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 10),
            pw.Text("Total Cases: 47"),
            pw.Text("Urgent: 12"),
            pw.Text("Moderate: 18"),
            pw.Text("Mild: 17"),
            pw.SizedBox(height: 20),
            pw.Text("Recent Cases"),
            ...recentCases.map((c) => pw.Text(
                "${c["title"]} (${c["level"]}) - ${c["time"]}")),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = {
      "total": 47,
      "urgent": 12,
      "moderate": 18,
      "mild": 17,
    };

    final weekly = [5, 8, 3, 7, 6, 4, 3];
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    final recentCases = [
      {
        "title": "🔴 Dengue fever",
        "time": "2 hr ago",
        "condition": "Suspected dengue",
        "do_now": ["Give fluids", "Monitor fever"]
      },
      {
        "title": "🟡 Burns",
        "time": "6 hr ago",
        "condition": "Second degree burn",
        "do_now": ["Cool water", "Cover wound"]
      },
      {
        "title": "🟢 Cold",
        "time": "Yesterday",
        "condition": "Viral cold",
        "do_now": ["Rest", "Hydrate"]
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _drawer(context),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),

        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

        title: const Text(
          "OfflineMedic Dashboard",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => exportReport(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// STATS
            Row(
              children: [
                _stat("Total", "47", Colors.blue),
                const SizedBox(width: 10),
                _stat("Urgent", "12", Colors.red),
                const SizedBox(width: 10),
                _stat("Moderate", "18", Colors.orange),
                const SizedBox(width: 10),
                _stat("Mild", "17", Colors.green),
              ],
            ),

            const SizedBox(height: 24),

            /// PIE CHART (FIXED SIZE)
            const Text("Triage Distribution",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: 12,
                      color: Colors.red,
                      title: "Urgent\n12",
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 18,
                      color: Colors.orange,
                      title: "Moderate\n18",
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 11),
                    ),
                    PieChartSectionData(
                      value: 17,
                      color: Colors.green,
                      title: "Mild\n17",
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// BAR CHART
            const Text("Cases This Week",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),

                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Text(days[value.toInt()]);
                        },
                      ),
                    ),
                  ),

                  barGroups: List.generate(
                    weekly.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weekly[i].toDouble(),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// RESTORED COMPONENTS
            const Text("Most Common Condition",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("Fever"),
            ),

            const SizedBox(height: 24),

            const Text("Today",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("3 cases handled"),

            const SizedBox(height: 24),

            /// RECENT CASES (EXPANDABLE)
            const Text("Recent Cases",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Column(
              children: recentCases
                  .map((c) => ExpandableCase(data: c))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("OfflineMedic",
                style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            title: const Text("Input"),
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/input'),
          ),
          ListTile(
            title: const Text("Dashboard"),
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            title: const Text("Map"),
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/map'),
          ),
        ],
      ),
    );
  }

  static Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// 🔽 EXPANDABLE CASE
class ExpandableCase extends StatefulWidget {
  final Map<String, dynamic> data;

  const ExpandableCase({super.key, required this.data});

  @override
  State<ExpandableCase> createState() => _ExpandableCaseState();
}

class _ExpandableCaseState extends State<ExpandableCase> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Expanded(child: Text(widget.data["title"])),
                Text(widget.data["time"]),
              ],
            ),

            if (expanded) ...[
              const SizedBox(height: 8),
              Text("Condition: ${widget.data["condition"]}"),
              const SizedBox(height: 6),
              const Text("Do Now:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.data["do_now"]
                  .map<Widget>((e) => Text("• $e"))
                  .toList(),
            ]
          ],
        ),
      ),
    );
  }
}