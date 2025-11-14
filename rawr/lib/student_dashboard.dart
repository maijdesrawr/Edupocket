import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'student_graphs.dart' as graphs;
import 'student_profile.dart';
import 'student_topups.dart';

class StudentDashboard extends StatefulWidget {
  final String name;
  final String id;

  const StudentDashboard({super.key, required this.name, required this.id});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String selectedFilter = 'Monthly';
  List<Map<String, dynamic>> transactions = [];
  double totalBalance = 0.0;
  double totalExpense = 0.0;
  bool isLoading = true;

  final String apiUrl = 'http://10.104.13.218:8000/student_transactions.php';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$apiUrl?student_id=${widget.id}&filter=$selectedFilter'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final txList = (data['transactions'] ?? []) as List;

          final txData = txList.map((tx) {
            final type = tx['transaction_type']?.toString() ?? '';
            final desc = tx['description']?.toString() ?? '';
            final date = tx['date_time']?.toString() ?? '';
            final amount =
                double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;

            IconData icon;
            switch (type.toLowerCase()) {
              case 'top-up':
                icon = Icons.add_card;
                break;
              case 'payment':
                icon = Icons.restaurant;
                break;
              case 'transfer':
                icon = Icons.account_balance_wallet_outlined;
                break;
              default:
                icon = Icons.help_outline;
            }

            return {
              'type': type,
              'desc': desc,
              'amount': amount,
              'date': date,
              'status': tx['status']?.toString() ?? '',
              'icon': icon,
            };
          }).toList();

          setState(() {
            transactions = txData;
            totalBalance =
                double.tryParse(data['total_balance']?.toString() ?? '0') ??
                    0.0;
            totalExpense =
                double.tryParse(data['total_expense']?.toString() ?? '0') ??
                    0.0;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
        print('Error fetching transactions: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Exception fetching transactions: $e');
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Total Balance",
                          style: TextStyle(
                            color: vividRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "\$${totalBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: vividRed,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 40, width: 1, color: Colors.red.shade200),
                    Column(
                      children: [
                        const Text(
                          "Total Expense",
                          style: TextStyle(
                            color: vividRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "-\$${totalExpense.abs().toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: vividRed,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                          // ---- Filter Tabs ----
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['Daily', 'Weekly', 'Monthly'].map((
                                filter,
                              ) {
                                bool selected = selectedFilter == filter;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedFilter = filter);
                                    fetchTransactions();
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
                                      borderRadius: BorderRadius.circular(25),
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
                            "Recent Activity",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : transactions.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No transactions found",
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: transactions.length,
                                        itemBuilder: (context, index) {
                                          final tx = transactions[index];
                                          bool isPositive = tx['amount'] > 0;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(
                                                      0.2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  child: Icon(
                                                    tx['icon'],
                                                    color: tx['type']
                                                                .toLowerCase() ==
                                                            'payment'
                                                        ? const Color.fromARGB(
                                                            255,
                                                            255,
                                                            179,
                                                            179,
                                                          )
                                                        : tx['type'].toLowerCase() ==
                                                                'top-up'
                                                            ? Colors.greenAccent
                                                            : Colors.white,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        tx['type'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        tx['desc'],
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      Text(
                                                        tx['date'],
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      "${tx['amount'].toStringAsFixed(2)}",
                                                      style: TextStyle(
                                                        color: tx['type']
                                                                    .toLowerCase() ==
                                                                'payment'
                                                            ? const Color
                                                                .fromARGB(
                                                                255,
                                                                255,
                                                                142,
                                                                142,
                                                              )
                                                            : tx['type'].toLowerCase() ==
                                                                    'top-up'
                                                                ? Colors
                                                                    .greenAccent
                                                                : Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      tx['status'],
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                    active: true,
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'Graphs',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => graphs.StudentGraphs(
                            name: widget.name,
                            id: widget.id,
                          ),
                        ),
                      );
                    },
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

// ---- laman ng nav ----
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
