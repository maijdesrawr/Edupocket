import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rawr/pos_payment_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Map<String, List<PaymentTransaction>> _groupedTransactions = {};
  late List<String> _groupKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.104.13.218:8000/kuhanin_transakyones.php'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          final List<PaymentTransaction> transactions = data.map((txn) {
            return PaymentTransaction(
              id: txn['id'].toString(),
              recipientName: txn['recipientName'],
              recipientNumber: txn['recipientNumber'],
              paymentTitle: txn['paymentTitle'],
              amount: txn['amount'].toDouble(),
              timestamp: DateTime.parse(txn['timestamp']),
              isCompleted: txn['isCompleted'],
            );
          }).toList();

          setState(() {
            _groupedTransactions = _groupByDate(transactions);
            _groupKeys = _groupedTransactions.keys.toList();
            _isLoading = false;
          });
        }
      } else {
        print('Failed to fetch transactions');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<PaymentTransaction>> _groupByDate(
      List<PaymentTransaction> txns) {
    Map<String, List<PaymentTransaction>> grouped = {};
    for (var txn in txns) {
      String key = _getDateLabel(txn.timestamp);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(txn);
    }
    return grouped;
  }

  String _getDateLabel(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime txnDate = DateTime(date.year, date.month, date.day);

    if (txnDate == today) return 'Today';

    DateTime yesterday = today.subtract(const Duration(days: 1));
    if (txnDate == yesterday) return 'Yesterday';

    return _getMonthName(date.month);
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                          const Text(
                            'Welcome',
                            style: TextStyle(
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
                        padding: const EdgeInsets.only(top: 24.0),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            ..._groupKeys.expand((key) {
                              final transactions = _groupedTransactions[key]!;
                              return [
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _StickyHeaderDelegate(
                                    child: Container(
                                      height: 40.0,
                                      color: const Color(0xFFAC2324),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        key,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final isFirstItem = index == 0;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              top: isFirstItem ? 8.0 : 0.0),
                                          child: _buildTransactionTile(
                                              transactions[index]),
                                        );
                                      },
                                      childCount: transactions.length,
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                    child: SizedBox(height: 16)),
                              ];
                            }),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionTile(PaymentTransaction txn) {
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 40.0;

  @override
  double get minExtent => 40.0;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
