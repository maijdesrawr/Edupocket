import 'package:flutter/material.dart';
import 'package:rawr/pos_payment_model.dart';
import 'pos_transaction_history_screen.dart';
import 'pos_qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String name;
  final String id;
  final void Function(int index)? onNavigate;

  const DashboardScreen({
    super.key,
    required this.name,
    required this.id,
    this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  final List<PaymentTransaction> _recentTransactions = [
    PaymentTransaction(
      id: '1',
      recipientName: 'Raizza Ignacio',
      recipientNumber: '...',
      paymentTitle: 'Tuition Payment',
      amount: 4685.00,
      timestamp: DateTime(2025, 10, 2, 15, 22),
      isCompleted: true,
    ),
    PaymentTransaction(
      id: '2',
      recipientName: 'Emma Wilson',
      recipientNumber: '...',
      paymentTitle: 'Tuition Payment',
      amount: 1500.00,
      timestamp: DateTime(2025, 10, 1, 13, 10),
      isCompleted: true,
    ),
    PaymentTransaction(
      id: '3',
      recipientName: 'Emma Wilson',
      recipientNumber: '...',
      paymentTitle: 'Field Trip',
      amount: 1500.00,
      timestamp: DateTime(2025, 10, 1, 13, 10),
      isCompleted: true,
    ),
    PaymentTransaction(
      id: '4',
      recipientName: 'John Doe',
      recipientNumber: '...',
      paymentTitle: 'Book Fee',
      amount: 500.00,
      timestamp: DateTime(2025, 10, 1, 10, 05),
      isCompleted: true,
    ),
    PaymentTransaction(
      id: '5',
      recipientName: 'Jane Smith',
      recipientNumber: '...',
      paymentTitle: 'Cafeteria Load',
      amount: 1000.00,
      timestamp: DateTime(2025, 9, 30, 11, 15),
      isCompleted: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildMainDashboard(), // Home
      const TransactionHistoryScreen(),
      const QRScannerScreen(),
    ];
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onNavigate?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Image.asset(
        'assets/icons/logo-red.png',
        height: 60,
      ),
      centerTitle: true,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(74.0),
          topRight: Radius.circular(74.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            iconRed: 'assets/icons/home-red.png',
            iconWhite: 'assets/icons/home-white.png',
            index: 0,
          ),
          _navItem(
            iconRed: 'assets/icons/history-red.png',
            iconWhite: 'assets/icons/history-white.png',
            index: 1,
          ),
          _navItem(
            iconRed: 'assets/icons/qr-red.png',
            iconWhite: 'assets/icons/qr-white.png',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required String iconRed,
    required String iconWhite,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFAC2324) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(isSelected ? iconWhite : iconRed),
      ),
    );
  }

  // ------------------ Main Dashboard ------------------
  Widget _buildMainDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Welcome "${widget.name}"',
                    style: const TextStyle(
                      color: Color(0xFFAC2324),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Image.asset(
                'assets/icons/user-circle-single.png',
                width: 60,
                height: 60,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFAC2324),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(74.0),
                topRight: Radius.circular(74.0),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(74.0),
                topRight: Radius.circular(74.0),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceBox(),
                    const SizedBox(height: 20),
                    _buildQuickActionsSection(context),
                    const SizedBox(height: 20),
                    _buildRecentTransactionsHeader(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24.0),
                        itemCount: _recentTransactions.length,
                        itemBuilder: (context, index) {
                          return _transactionTile(_recentTransactions[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.name} account current balance:',
              style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(
            '₱7,783.00',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFAC2324)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionButton(
                'Transaction History',
                Icons.history,
                () => _onNavTap(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _quickActionButton(
                'QR Scanner',
                Icons.qr_code_scanner,
                () => _onNavTap(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(26),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFAC2324), size: 22),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return const Text('Recent Transaction Activity',
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _transactionTile(PaymentTransaction txn) {
    String formatDate(DateTime dt) {
      final String date =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final int hour =
          dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final String time =
          '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      return '$date • $time';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.recipientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '${txn.paymentTitle} • ${formatDate(txn.timestamp)}',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+₱${txn.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 2),
              const Text('Completed',
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
