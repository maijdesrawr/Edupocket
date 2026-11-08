import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'app_session_service.dart';
import 'parent_bottom_nav.dart';
import 'parent_profile.dart';
import 'profile_avatar.dart';
import 'topup.dart';
import 'transaction_history.dart';

class ParentGraphs extends StatefulWidget {
  final String name;
  final String id;
  final List<Map<String, dynamic>> children;
  final String? selectedChildId;

  const ParentGraphs({
    super.key,
    required this.name,
    required this.id,
    required this.children,
    this.selectedChildId,
  });

  @override
  State<ParentGraphs> createState() => _ParentGraphsState();
}

class _ParentGraphsState extends State<ParentGraphs> {
  static const Color _primaryRed = Color(0xFFC62828);
  static const Color _deepRed = Color(0xFFB71C1C);
  static const Color _softPink = Color(0xFFF0B8AC);
  static const Color _panelPink = Color(0xFFF2B2A9);
  static const Color _successGreen = Color(0xFF129D37);
  static const Color _expenseOrange = Color(0xFFF57C00);

  String _selectedFilter = 'Daily';
  String? _selectedChildId;
  bool _isLoading = false;
  double _totalBalance = 0;
  double _totalExpense = 0;
  List<_ParentGraphData> _topups = [];
  List<_ParentGraphData> _expenses = [];

  Map<String, dynamic>? get _selectedChild {
    for (final child in widget.children) {
      if ((child['child_id'] ?? '').toString() == _selectedChildId) {
        return child;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    if (widget.children.isNotEmpty) {
      final requestedId = widget.selectedChildId;
      final exists = widget.children.any(
        (child) => (child['child_id'] ?? '').toString() == requestedId,
      );

      _selectedChildId = exists
          ? requestedId
          : (widget.children.first['child_id'] ?? '').toString();

      _totalBalance = _asDouble(_selectedChild?['balance']);
      _fetchGraphData();
    }
  }

  Future<void> _fetchGraphData() async {
    final studentNum = _selectedChildId;
    final requestedFilter = _selectedFilter;

    if (studentNum == null || studentNum.isEmpty) return;

    setState(() {
      _isLoading = true;
      _totalBalance = _asDouble(_selectedChild?['balance']);
    });

    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.url(
            'parent_graphs.php?parent_id=${Uri.encodeQueryComponent(widget.id)}&student_num=${Uri.encodeQueryComponent(studentNum)}&filter=${Uri.encodeQueryComponent(requestedFilter)}',
          ),
        ),
        headers: AppSessionService.instance.authorizationHeaders,
      );

      if (await AppSessionService.instance.handleResponse(response)) {
        return;
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonData['status'] == 'success') {
          final rawData = List<Map<String, dynamic>>.from(
            jsonData['data'] ?? const [],
          );

          final Map<String, double> groupedTopups = {};
          final Map<String, double> groupedExpenses = {};

          for (final item in rawData) {
            final label = (item['label'] ?? '').toString();
            final topup = _asDouble(item['topup']);
            final expense = _asDouble(item['expense']);

            groupedTopups[label] = (groupedTopups[label] ?? 0) + topup;
            groupedExpenses[label] = (groupedExpenses[label] ?? 0) + expense;
          }

          final fetchedTopups = groupedTopups.entries
              .map((entry) => _ParentGraphData(entry.key, entry.value))
              .toList();

          final fetchedExpenses = groupedExpenses.entries
              .map((entry) => _ParentGraphData(entry.key, entry.value))
              .toList();

          final expenseTotal = _asDouble(jsonData['total_expense']);

          if (!mounted ||
              requestedFilter != _selectedFilter ||
              studentNum != _selectedChildId) {
            return;
          }

          setState(() {
            _topups = fetchedTopups;
            _expenses = fetchedExpenses;
            _totalExpense = expenseTotal;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Parent graphs fetch failed: $e');
    }

    if (!mounted ||
        requestedFilter != _selectedFilter ||
        studentNum != _selectedChildId) {
      return;
    }

    setState(() {
      _topups = [];
      _expenses = [];
      _totalExpense = 0;
      _isLoading = false;
    });
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }

    if (index == 1) return;

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TopUpContent(userName: widget.name, userId: widget.id),
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionHistoryPage(
            userName: widget.name,
            userId: widget.id,
          ),
        ),
      );
      return;
    }

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParentProfilePage(
            userName: widget.name,
            userId: widget.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _selectedChild;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Center(
              child: Image.asset(
                'assets/redlogo.png',
                height: 74,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            color: _primaryRed,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _deepRed,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProfileAvatar(
                    role: 'parent',
                    userId: widget.id,
                    radius: 40,
                    fallbackIcon: Icons.person,
                    iconColor: _primaryRed,
                    backgroundColor: const Color(0xFFE7F0FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryItem(
                      'Total Balance',
                      _formatCurrency(_totalBalance),
                      _successGreen,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: _primaryRed.withValues(alpha: 0.35),
                  ),
                  Expanded(
                    child: _summaryItem(
                      'Total Expense',
                      _formatCurrency(_totalExpense, negative: true),
                      _primaryRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _primaryRed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(42),
                    topRight: Radius.circular(42),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChildSelector(),
                      const SizedBox(height: 16),
                      _buildFilterShell(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              child == null
                                  ? 'Student Transaction Graph'
                                  : '${child['child_name'] ?? 'Student'}\'s Transaction Graph',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _legendChip(_successGreen, 'Top-Up'),
                          const SizedBox(width: 8),
                          _legendChip(_expenseOrange, 'Expense'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(child: _buildChartPanel()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ParentBottomNav(
        selectedIndex: 1,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildChildSelector() {
    if (widget.children.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          'No linked students available.',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(widget.children.length, (index) {
            final child = widget.children[index];
            final childId = (child['child_id'] ?? '').toString();
            final selected = childId == _selectedChildId;

            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.children.length - 1 ? 0 : 8,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (childId == _selectedChildId) return;

                  setState(() {
                    _selectedChildId = childId;
                    _totalBalance = _asDouble(child['balance']);
                    _totalExpense = 0;
                    _topups = [];
                    _expenses = [];
                  });

                  _fetchGraphData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 140,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? _deepRed : _softPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    (child['child_name'] ?? 'Student').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : _primaryRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterShell() {
    const filters = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: filter == filters.first ? 0 : 4,
                right: filter == filters.last ? 0 : 4,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (_selectedFilter == filter) return;
                  setState(() => _selectedFilter = filter);
                  _fetchGraphData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? _deepRed : _softPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: selected ? Colors.white : _primaryRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _legendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildChartPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: _panelPink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryRed),
            )
          : widget.children.isEmpty
              ? const Center(
                  child: Text(
                    'No linked students available.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : _topups.isEmpty && _expenses.isEmpty
                  ? const Center(
                      child: Text(
                        'No graph data available.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            color: _primaryRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _ParentBarChart(
                            topups: _topups,
                            expenses: _expenses,
                            filter: _selectedFilter,
                            childName:
                                (_selectedChild?['child_name'] ?? 'Student')
                                    .toString(),
                          ),
                        ),
                      ],
                    ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCurrency(double value, {bool negative = false}) {
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${negative ? '-₱' : '₱'}$whole.${parts[1]}';
  }
}

class _ParentGraphData {
  final String label;
  final double value;

  _ParentGraphData(this.label, this.value);
}

class _ParentBarChart extends StatelessWidget {
  final List<_ParentGraphData> topups;
  final List<_ParentGraphData> expenses;
  final String filter;
  final String childName;

  const _ParentBarChart({
    required this.topups,
    required this.expenses,
    required this.filter,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    final maxLength =
        topups.length > expenses.length ? topups.length : expenses.length;

    if (maxLength == 0) return const SizedBox.shrink();

    var maxY = 0.0;

    for (final item in [...topups, ...expenses]) {
      if (item.value > maxY) maxY = item.value;
    }

    maxY = maxY <= 0 ? 1000 : maxY * 1.2;
    final interval = maxY / 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        groupsSpace: 16,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = rodIndex == 0
                  ? (groupIndex < topups.length ? topups[groupIndex] : null)
                  : (groupIndex < expenses.length
                      ? expenses[groupIndex]
                      : null);

              final type = rodIndex == 0 ? 'Top-Up' : 'Expense';

              return BarTooltipItem(
                '$type\n${item?.label ?? ''}\n₱${rod.toY.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            if (event is FlTapUpEvent &&
                response != null &&
                response.spot != null) {
              final groupIndex = response.spot!.touchedBarGroupIndex;
              final rodIndex = response.spot!.touchedRodDataIndex;

              if (groupIndex < 0) return;

              _ParentGraphData? selectedItem;

              if (rodIndex == 0) {
                if (groupIndex < topups.length) {
                  selectedItem = topups[groupIndex];
                }
              } else {
                if (groupIndex < expenses.length) {
                  selectedItem = expenses[groupIndex];
                }
              }

              if (selectedItem == null) return;

              final topupValue =
                  groupIndex < topups.length ? topups[groupIndex].value : 0.0;

              final expenseValue = groupIndex < expenses.length
                  ? expenses[groupIndex].value
                  : 0.0;

              _showInterpretationDialog(
                context,
                type: rodIndex == 0 ? 'Top-Up' : 'Expense',
                item: selectedItem,
                topupValue: topupValue,
                expenseValue: expenseValue,
              );
            }
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0x66C62828),
            strokeWidth: 1,
            dashArray: const [4, 3],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactPeso(value),
                  style: const TextStyle(
                    color: Color(0xFFB73D35),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final label = index < topups.length
                    ? topups[index].label
                    : (index < expenses.length ? expenses[index].label : '');

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _displayLabel(label, filter),
                    style: const TextStyle(
                      color: Color(0xFFB73D35),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(maxLength, (index) {
          final topup = index < topups.length ? topups[index].value : 0.0;
          final expense = index < expenses.length ? expenses[index].value : 0.0;

          return BarChartGroupData(
            x: index,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: topup,
                color: const Color(0xFF129D37),
                width: 10,
                borderRadius: BorderRadius.circular(6),
              ),
              BarChartRodData(
                toY: expense,
                color: const Color(0xFFF57C00),
                width: 10,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showInterpretationDialog(
    BuildContext context, {
    required String type,
    required _ParentGraphData item,
    required double topupValue,
    required double expenseValue,
  }) {
    final isTopUp = type == 'Top-Up';

    final interpretation = _generateInterpretation(
      type: type,
      topupValue: topupValue,
      expenseValue: expenseValue,
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isTopUp
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isTopUp
                            ? Icons.account_balance_wallet_rounded
                            : Icons.shopping_cart_rounded,
                        color: isTopUp
                            ? const Color(0xFF129D37)
                            : const Color(0xFFF57C00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTopUp
                                ? 'Money Received'
                                : 'Spending Interpretation',
                            style: const TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _periodLabel(),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₱${item.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isTopUp
                              ? const Color(0xFF129D37)
                              : const Color(0xFFF57C00),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'What this means',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  interpretation,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryValue(
                          'Top-Up',
                          topupValue,
                          const Color(0xFF129D37),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.black12,
                      ),
                      Expanded(
                        child: _summaryValue(
                          'Expense',
                          expenseValue,
                          const Color(0xFFF57C00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _generateInterpretation({
    required String type,
    required double topupValue,
    required double expenseValue,
  }) {
    if (type == 'Top-Up') {
      if (topupValue == 0) {
        return 'No money was added to $childName\'s wallet '
            'during this period.';
      }

      if (expenseValue == 0) {
        return '$childName received '
            '₱${topupValue.toStringAsFixed(2)} during this period '
            'and did not record any expenses.';
      }

      if (topupValue > expenseValue) {
        final remaining = topupValue - expenseValue;

        return '$childName received '
            '₱${topupValue.toStringAsFixed(2)} and spent '
            '₱${expenseValue.toStringAsFixed(2)} during this period. '
            'The amount received was higher than the recorded expenses '
            'by ₱${remaining.toStringAsFixed(2)}.';
      }

      if (expenseValue > topupValue) {
        final difference = expenseValue - topupValue;

        return '$childName received '
            '₱${topupValue.toStringAsFixed(2)} but spent '
            '₱${expenseValue.toStringAsFixed(2)} during this period. '
            'The recorded expenses were higher than the top-ups '
            'by ₱${difference.toStringAsFixed(2)}.';
      }

      return '$childName received and spent the same amount '
          'during this period.';
    }

    if (expenseValue == 0) {
      return '$childName student did not record any expenses '
          'during this period.';
    }

    if (topupValue == 0) {
      return '$childName student spent '
          '₱${expenseValue.toStringAsFixed(2)} during this period. '
          'No top-ups were recorded during the same period.';
    }

    if (expenseValue < topupValue) {
      final remaining = topupValue - expenseValue;

      return '$childName student received '
          '₱${topupValue.toStringAsFixed(2)} and spent '
          '₱${expenseValue.toStringAsFixed(2)} during this period. '
          'The top-ups were higher than the recorded expenses '
          'by ₱${remaining.toStringAsFixed(2)}.';
    }

    if (expenseValue > topupValue) {
      final difference = expenseValue - topupValue;

      return '$childName student received '
          '₱${topupValue.toStringAsFixed(2)} and spent '
          '₱${expenseValue.toStringAsFixed(2)} during this period. '
          'The recorded expenses were higher than the top-ups '
          'by ₱${difference.toStringAsFixed(2)}.';
    }

    return '$childName student spent the same amount '
        'as the total top-ups received during this period.';
  }

  String _periodLabel() {
    switch (filter) {
      case 'Daily':
        return 'Daily transaction';

      case 'Weekly':
        return 'Weekly transaction';

      case 'Monthly':
        return 'Monthly transaction';

      case 'Yearly':
        return 'Yearly transaction';

      default:
        return 'Transaction';
    }
  }

  Widget _summaryValue(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₱${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  static String _compactPeso(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return value.toInt().toString();
  }

  static String _displayLabel(String label, String filter) {
    if (label.trim().isEmpty) return '';

    final parsed = DateTime.tryParse(label);

    if (parsed != null && filter == 'Daily') {
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[parsed.weekday - 1];
    }

    if (filter == 'Monthly') {
      final parts = label.split(' ');
      return parts.isNotEmpty ? parts.first : label;
    }

    return label;
  }
}
