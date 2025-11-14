import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'topup.dart';
import 'transaction_history.dart';

class ParentDashboard extends StatefulWidget {
  final String name;
  final String id;

  const ParentDashboard({super.key, required this.name, required this.id});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  static const Color pastelLight = Color(0xFFfde2d5);
  static const Color vividRed = Color(0xFFcf302e);
  static const Color deepRed = Color(0xFFac2324);
  static const Color paleBlush = Color(0xFFeeb3a9);

  bool isLoading = true;
  double totalBalance = 0.0;
  double totalExpense = 0.0;

  List<Map<String, dynamic>> children = [];
  List<Map<String, dynamic>> _activities = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final url = Uri.parse(
        'http://10.104.13.218:8000/parent_dashboard.php?parent_id=${widget.id}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final fetchedChildren = List<Map<String, dynamic>>.from(
            data['children'] ?? [],
          );
          _tabController = TabController(
            length: fetchedChildren.isNotEmpty ? fetchedChildren.length : 1,
            vsync: this,
          );

          setState(() {
            totalBalance = (data['total_balance'] ?? 0).toDouble();
            totalExpense = (data['total_expense'] ?? 0).toDouble();
            children = fetchedChildren;
            _activities = List<Map<String, dynamic>>.from(
              data['activities'] ?? [],
            );
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          print("API Error: ${data['message']}");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TopUpContent(userName: widget.name, userId: widget.id),
        ),
      );

      if (result == true) {
        _fetchDashboardData();
      }
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TransactionHistoryPage(userName: widget.name, userId: widget.id),
        ),
      );
    }
  }

  Widget _buildChildDashboard(Map<String, dynamic> child) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: pastelLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${child['child_name']}'s Account Report Balance:",
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱ ${(child['balance'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: deepRed,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Total Expense',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱ ${(child['expense'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: deepRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildActivityList(child['child_id']),
      ],
    );
  }

  Widget _buildActivityList(String? childId) {
    final childActivities = _activities.where((activity) {
      return activity['child_id'] == childId;
    }).toList();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: paleBlush,
          borderRadius: BorderRadius.circular(14),
        ),
        child: childActivities.isEmpty
            ? const Center(
                child: Text(
                  "No transactions found for this child.",
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: childActivities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = childActivities[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item['note']} • ${item['date']}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item['amount'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = children.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Center(child: Image.asset("assets/redlogo.png", height: 60)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good Morning',
                              style: TextStyle(color: vividRed, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Welcome ${widget.name}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: vividRed,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Column(
                              children: [
                                if (hasChildren)
                                  TabBar(
                                    controller: _tabController,
                                    indicatorColor: Colors.white,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white70,
                                    tabs: [
                                      for (var child in children)
                                        Tab(text: child['child_name']),
                                    ],
                                  ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: hasChildren
                                      ? TabBarView(
                                          controller: _tabController,
                                          children: [
                                            for (var child in children)
                                              _buildChildDashboard(child),
                                          ],
                                        )
                                      : _buildChildDashboard({
                                          'child_id': 'none',
                                          'child_name': 'No linked student',
                                          'balance': 0.0,
                                          'expense': 0.0,
                                        }),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: vividRed,
                unselectedItemColor: Colors.black54,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline),
                    label: 'Top-Up',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Transaction History',
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
