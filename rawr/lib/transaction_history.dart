import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'parent.dart';
import 'topup.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String userName;
  final String userId;

  const TransactionHistoryPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  int _selectedIndex = 2;

  static const Color pastelLight = Color(0xFFfde2d5);
  static const Color vividRed = Color(0xFFcf302e);
  static const Color deepRed = Color(0xFFac2324);
  static const Color paleBlush = Color(0xFFeeb3a9);

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _children = [];

  bool isLoading = true;
  String? _selectedChildId;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      final url = Uri.parse(
        'http://10.104.13.218:8000/get_linked_children.php?parent_id=${widget.userId}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _children = List<Map<String, dynamic>>.from(data['children']);
            if (_children.isNotEmpty) {
              _selectedChildId = _children.first['student_num'];
            }
          });
          await _fetchTransactions();
        }
      }
    } catch (e) {
      print('Error fetching children: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    if (_selectedChildId == null) return;
    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        'http://10.104.13.218:8000/transaction_history.php?parent_id=${widget.userId}&child_id=$_selectedChildId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(
              data['transactions'],
            );
          });
        } else {
          setState(() => _transactions = []);
        }
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ParentDashboard(name: widget.userName, id: widget.userId),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TopUpContent(userName: widget.userName, userId: widget.userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTransactions = _transactions.where((tx) {
      final note = (tx['note'] ?? '').toString().toLowerCase();

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Top-ups') {
        return note.contains('top-up') || note.contains('deposit');
      } else if (_selectedFilter == 'Expenses') {
        return note.contains('payment') ||
            note.contains('purchase') ||
            note.contains('canteen') ||
            note.contains('spent') ||
            note.contains('expense');
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Red background container
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(top: 200),
              decoration: const BoxDecoration(
                color: vividRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),

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
                              'Welcome ${widget.userName}',
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

                // --- Content ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Child selection dropdown
                        if (_children.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedChildId,
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: "Select Child",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _children.map((child) {
                              return DropdownMenuItem<String>(
                                value: child['student_num'],
                                child: Text(child['Fname']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedChildId = value;
                              });
                              _fetchTransactions();
                            },
                          ),
                        const SizedBox(height: 14),

                        Text(
                          "Transaction History",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filter buttons
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Top-ups', 'Expenses'].map((
                              filter,
                            ) {
                              bool isSelected = _selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : deepRed,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? deepRed
                                          : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = filter;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        filter,
                                        style: TextStyle(
                                          color: isSelected
                                              ? deepRed
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Transaction List
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: paleBlush,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: vividRed,
                                    ),
                                  )
                                : filteredTransactions.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No transactions found.",
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filteredTransactions.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final tx =
                                              filteredTransactions[index];
                                          final note =
                                              (tx['note'] ?? '').toString();
                                          final name =
                                              (tx['name'] ?? '').toString();
                                          final date =
                                              (tx['date'] ?? '').toString();
                                          final amount =
                                              (tx['amount'] ?? '0').toString();
                                          final isTopUp =
                                              tx['is_topup'] == true;

                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                12,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: isTopUp
                                                        ? Colors.green
                                                        : vividRed,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        note,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '$name • $date',
                                                        style: const TextStyle(
                                                          color: Colors.black54,
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
                                                      amount,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isTopUp
                                                            ? Colors.green
                                                            : vividRed,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      isTopUp
                                                          ? 'Credited'
                                                          : 'Debited',
                                                      style: const TextStyle(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom navigation
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
