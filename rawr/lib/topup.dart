import 'package:flutter/material.dart';
import 'package:rawr/parent.dart' as parent_page;
import 'payment.dart';
import 'transaction_history.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TopUpContent extends StatefulWidget {
  final String userName;
  final String userId;

  const TopUpContent({super.key, required this.userName, required this.userId});

  @override
  State<TopUpContent> createState() => _TopUpContentState();
}

class _TopUpContentState extends State<TopUpContent> {
  int _selectedIndex = 1;
  double? _highlightedAmount;
  bool _customSelected = false;

  String? _selectedChildId;
  String? _selectedChildName;
  List<Map<String, String>> _children = [];

  static const Color pastelLight = Color(0xFFfde2d5);
  static const Color vividRed = Color(0xFFcf302e);
  static const Color deepRed = Color(0xFFac2324);
  static const Color paleBlush = Color(0xFFeeb3a9);

  final List<Map<String, double>> topUpOptions = [
    {'amount': 500},
    {'amount': 1000},
    {'amount': 1500},
    {'amount': 3000},
    {'amount': 5000},
    {'amount': 7000},
  ];

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.104.13.218:8000/get_linked_children.php?parent_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _children = (data['children'] as List)
                .map<Map<String, String>>(
                  (child) => {
                    'id': child['student_num'].toString(),
                    'name': child['Fname'].toString(),
                  },
                )
                .toList();

            final ids = <String>{};
            _children = _children.where((c) => ids.add(c['id']!)).toList();

            if (_children.isNotEmpty) {
              _selectedChildId = _children[0]['id'];
              _selectedChildName = _children[0]['name'];
            }
          });
        }
      } else {
        setState(() {
          _children = [];
        });
      }
    } catch (e) {
      setState(() {
        _children = [];
      });
      print("Error fetching children: $e");
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
          builder: (context) => parent_page.ParentDashboard(
            name: widget.userName,
            id: widget.userId,
          ),
        ),
      );
    } else if (index == 1) {
      // Already on Top-Up
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionHistoryPage(
            userName: widget.userName,
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  void _goToWallet(double amount, {bool isCustom = false}) async {
    if (_selectedChildId == null || _selectedChildName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a child')));
      return;
    }

    setState(() {
      _highlightedAmount = amount;
      _customSelected = isCustom;
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletPage(
          userName: widget.userName,
          userId: widget.userId,
          amount: amount,
          selectedChildId: _selectedChildId!,
          selectedChildName: _selectedChildName!,
        ),
      ),
    );

    if (result == true) {
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showInputAmountDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Top-Up Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Minimum Php 200'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = double.tryParse(controller.text);
              if (input == null || input < 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimum amount is Php 200')),
                );
              } else {
                Navigator.pop(context);
                _goToWallet(input, isCustom: true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // da container
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(top: 260),
              decoration: const BoxDecoration(
                color: vividRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),
          ),

          // da laman of da container
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Center(child: Image.asset('assets/redlogo.png', height: 60)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                            const SizedBox(height: 8),
                            if (_children.isNotEmpty)
                              DropdownButton<String>(
                                value: _selectedChildId,
                                items: _children
                                    .map(
                                      (child) => DropdownMenuItem<String>(
                                        value: child['id'],
                                        child: Text(
                                          child['name']!,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedChildId = value;
                                    _selectedChildName = _children.firstWhere(
                                      (child) => child['id'] == value,
                                    )['name'];
                                  });
                                },
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
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: paleBlush,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListView.builder(
                                itemCount: topUpOptions.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < topUpOptions.length) {
                                    final option = topUpOptions[index];
                                    bool isSelected = !_customSelected &&
                                        _highlightedAmount == option['amount'];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isSelected
                                              ? Colors.red.shade200
                                              : Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          _goToWallet(option['amount']!);
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.account_balance_wallet,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Top-Up',
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.red,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Php ${option['amount']!.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.red,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _customSelected
                                              ? Colors.red.shade200
                                              : Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        onPressed: _showInputAmountDialog,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              color: _customSelected
                                                  ? Colors.white
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Input Amount',
                                              style: TextStyle(
                                                color: _customSelected
                                                    ? Colors.white
                                                    : Colors.red,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
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

          // nabigasyones
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
