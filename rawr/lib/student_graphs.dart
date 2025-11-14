import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'student_profile.dart';
import 'student_topups.dart';
import 'student_dashboard.dart';

class StudentGraphs extends StatefulWidget {
  final String name;
  final String id;

  const StudentGraphs({super.key, required this.name, required this.id});

  @override
  State<StudentGraphs> createState() => _StudentGraphsState();
}

class _StudentGraphsState extends State<StudentGraphs> {
  String selectedFilter = 'Monthly';
  bool isLoading = true;
  List<GraphData> topups = [];
  List<GraphData> expenses = [];

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  Future<void> fetchGraphData() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
      'http://10.104.13.218:8000/student_graphs.php?student_num=${widget.id}&filter=$selectedFilter',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success') {
          final List data = jsonData['data'];
          List<GraphData> fetchedTopups = [];
          List<GraphData> fetchedExpenses = [];

          for (var item in data) {
            fetchedTopups.add(
              GraphData(item['label'], (item['topup'] ?? 0).toDouble()),
            );
            fetchedExpenses.add(
              GraphData(item['label'], (item['expense'] ?? 0).toDouble()),
            );
          }

          setState(() {
            topups = fetchedTopups;
            expenses = fetchedExpenses;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color vividRed = Color(0xFFcf302e);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),
          Positioned.fill(
            top: 280,
            child: Container(
              decoration: const BoxDecoration(
                color: vividRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/redlogo.png', width: 70),
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.account_circle_outlined,
                          color: vividRed,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Good Morning",
                        style: TextStyle(
                          color: vividRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Welcome, ${widget.name}",
                        style: const TextStyle(
                          color: vividRed,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: vividRed,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Tabs
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                                  .map((filter) {
                                bool selected = selectedFilter == filter;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedFilter = filter);
                                    fetchGraphData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? vividRed
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        25,
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        color:
                                            selected ? Colors.white : vividRed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Student Transactions Graph",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : topups.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No data available",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : Stack(
                                        children: [
                                          BarChartWidget(
                                            topups: topups,
                                            expenses: expenses,
                                            filter: selectedFilter,
                                          ),
                                          // ---- Legend Box ----
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 6,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  12,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  LegendItem(
                                                    color: Colors
                                                        .greenAccent.shade400,
                                                    label: 'Top-Up',
                                                  ),
                                                  const SizedBox(width: 10),
                                                  LegendItem(
                                                    color: Colors.orangeAccent,
                                                    label: 'Expense',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 90), // space for nav bar
              ],
            ),
          ),

          // ---- Bottom Navigation Bar ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home,
                    label: 'Home',
                    active: false,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDashboard(
                            name: widget.name,
                            id: widget.id,
                          ),
                        ),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'Graphs',
                    active: true,
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.swap_horiz,
                    label: 'Top-Ups',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentTopUps(name: widget.name, id: widget.id),
                        ),
                      );
                    },
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentProfile(id: widget.id, name: widget.name),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Nav Item ----
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color vividRed = Color(0xFFcf302e);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? vividRed : Colors.black45, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? vividRed : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class GraphData {
  final String label;
  final double value;
  GraphData(this.label, this.value);
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final List<GraphData> topups;
  final List<GraphData> expenses;
  final String filter;

  const BarChartWidget({
    super.key,
    required this.topups,
    required this.expenses,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    double maxY = 0;
    if ((topups + expenses).isNotEmpty) {
      maxY = (topups + expenses)
              .map((e) => e.value)
              .reduce((a, b) => a > b ? a : b) *
          1.2;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        groupsSpace: 22,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: maxY / 5,
              getTitlesWidget: (v, _) => Text(
                '₱${v.toInt()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (index, _) {
                if (index.toInt() >= topups.length) return const SizedBox();
                String label = topups[index.toInt()].label;

                if (filter == 'Weekly') {
                  label = 'W${index + 1}';
                } else if (label.contains('-')) {
                  final parts = label.split('-');
                  label = 'W${parts[1]}';
                } else if (label.length > 6) {
                  label = label.substring(0, 6);
                }

                return Transform.rotate(
                  angle: -0.4,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white12, strokeWidth: 1),
        ),
        barGroups: List.generate(topups.length, (i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: topups[i].value,
                color: Colors.greenAccent.shade400,
                width: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              BarChartRodData(
                toY: expenses[i].value,
                color: Colors.orangeAccent,
                width: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}
