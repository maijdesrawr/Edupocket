import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'admin_profile.dart';
import 'admin_report.dart';
import 'admin_users.dart';
import 'api_config.dart';
import 'app_session_service.dart';
import 'profile_avatar.dart';

class AdminHome extends StatefulWidget {
  final String name;
  final String id;

  const AdminHome({super.key, required this.name, required this.id});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  static const Color _primaryRed = Color(0xFFC62828);
  static const Color _deepRed = Color(0xFFB71C1C);
  static const Color _softRed = Color(0xFFD6322D);
  static const Color _cardShadow = Color(0x33000000);
  static const Color _mutedText = Color(0xFF8B8B8B);
  static const List<Color> _chartColors = [
    Color(0xFF7773E8),
    Color(0xFF53C5AE),
    Color(0xFFFF978E),
    Color(0xFFF2B44A),
  ];
  static const MethodChannel _exportChannel =
      MethodChannel('edupocket/admin_exports');

  int _selectedIndex = 0;
  int _totalUsers = 0;
  bool _showUserBreakdown = false;
  Map<String, int> _userBreakdown = const {
    'admins': 0,
    'students': 0,
    'canteens': 0,
    'cashiers': 0,
    'parents': 0,
  };
  double _totalBalance = 0.0;
  bool _isLoading = true;
  List<dynamic> _canteenSales = [];
  List<dynamic> _cashierSales = [];
  List<dynamic> _needsAttention = [];
  final Set<String> _selectedAlertKeys = {};
  bool _isSendingSelectedAlerts = false;
  bool _isDeletingSelectedAlerts = false;
  String _alertFilter = 'all';
  String _period = 'all';
  String _sort = 'sales';
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _showCashierSales = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      AppSessionService.instance.recordActivity(
        'dashboard_view',
        details: const {'dashboard': 'admin'},
      ),
    );
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final query = <String, String>{'period': _period, 'sort': _sort};
      if (_period == 'custom' && _customStart != null && _customEnd != null) {
        query['start_date'] = _dateKey(_customStart!);
        query['end_date'] = _dateKey(_customEnd!);
      }
      final uri = Uri.parse(ApiConfig.url('get_admin_dashboard.php'))
          .replace(queryParameters: query);
      final response = await http.get(uri,
          headers: AppSessionService.instance.authorizationHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _totalUsers = int.tryParse(data['total_users'].toString()) ?? 0;
          final breakdown = data['user_breakdown'];
          if (breakdown is Map) {
            _userBreakdown = {
              for (final role in const [
                'admins',
                'students',
                'canteens',
                'cashiers',
                'parents',
              ])
                role: int.tryParse('${breakdown[role]}') ?? 0,
            };
          }
          _totalBalance =
              double.tryParse(data['total_balance'].toString()) ?? 0.0;
          _canteenSales = List<dynamic>.from(data['canteen_sales'] ?? const []);
          _cashierSales = List<dynamic>.from(data['cashier_sales'] ?? const []);
          _needsAttention =
              List<dynamic>.from(data['needs_attention'] ?? const []);
          final currentKeys = _needsAttention
              .whereType<Map>()
              .map((alert) => _alertKey(Map<String, dynamic>.from(alert)))
              .toSet();
          _selectedAlertKeys.removeWhere((key) => !currentKeys.contains(key));
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminUsers(adminName: widget.name, adminId: widget.id),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminReportsPage(adminName: widget.name, adminId: widget.id),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminProfilePage(adminName: widget.name, adminId: widget.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/redlogo.png',
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            color: _softRed,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  _buildHeroAvatar(),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _primaryRed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildUserStatCard(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.payments_outlined,
                              label: 'Total Balance',
                              value: _isLoading
                                  ? '--'
                                  : _formatMoney(_totalBalance),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      Expanded(
                          child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          _buildSalesSection(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: _sectionTitle('Needs attention')),
                              _buildAlertFilterControl(),
                            ],
                          ),
                          const SizedBox(height: 9),
                          _buildNeedsAttention(),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));

  Future<void> _chooseCustomDates() async {
    final range = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _AdminDateRangePicker(
        initialRange: _customStart != null && _customEnd != null
            ? DateTimeRange(start: _customStart!, end: _customEnd!)
            : null,
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _customStart = range.start;
      _customEnd = range.end;
      _period = 'custom';
    });
    fetchDashboardData();
  }

  Widget _buildSalesSection() {
    final rows = _showCashierSales ? _cashierSales : _canteenSales;
    final chartRows = rows.take(10).toList();
    final values = chartRows.map((raw) {
      return _salesMetric(Map<String, dynamic>.from(raw as Map));
    }).toList();
    final maxMetric = values.fold<double>(0, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: DropdownButton<String>(
              value: _sort,
              underline: const SizedBox(),
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'sales', child: Text('Highest Sales')),
                DropdownMenuItem(
                  value: 'transactions',
                  child: Text('Most Transactions'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sort = value);
                fetchDashboardData();
              },
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    for (final filter in const [
                      ('all', 'All time'),
                      ('today', 'Today'),
                      ('week', 'Weekly'),
                      ('month', 'Monthly'),
                    ])
                      Expanded(
                        child: _periodButton(filter.$1, filter.$2),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            SizedBox.square(
              dimension: 42,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Choose date range',
                  onPressed: _chooseCustomDates,
                  icon: Icon(
                    Icons.calendar_month,
                    size: 19,
                    color: _period == 'custom' ? _deepRed : _primaryRed,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_period == 'custom' && _customStart != null && _customEnd != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_dateKey(_customStart!)} - ${_dateKey(_customEnd!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _showCashierSales ? 'By Cashier' : 'By Canteen',
                    style: const TextStyle(
                      color: _primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(
                      () => _showCashierSales = !_showCashierSales,
                    ),
                    child: Text(
                      _showCashierSales ? 'View Canteens' : 'View Cashiers',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Export sales table',
                    onPressed: () => _confirmExportSalesTable(rows),
                    icon: const Icon(
                      Icons.table_chart_outlined,
                      color: _primaryRed,
                    ),
                  ),
                ],
              ),
              if (chartRows.isEmpty)
                const SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'No sales for this period.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _HorizontalSalesPainter(
                            maximum: maxMetric,
                            sortByTransactions: _sort == 'transactions',
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 25),
                          child: Column(
                            children: List.generate(chartRows.length, (index) {
                              final item = Map<String, dynamic>.from(
                                  chartRows[index] as Map);
                              final sales =
                                  double.tryParse('${item['sales']}') ?? 0;
                              final transactions =
                                  int.tryParse('${item['payment_count']}') ?? 0;
                              final fraction = maxMetric > 0
                                  ? (values[index] / maxMetric)
                                      .clamp(0.025, 1.0)
                                      .toDouble()
                                  : 0.025;
                              final transactionLabel = transactions == 1
                                  ? '1 transaction'
                                  : '$transactions transactions';
                              return Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: fraction,
                                    child: Tooltip(
                                      triggerMode: TooltipTriggerMode.longPress,
                                      message:
                                          '${item['name']}\nTotal sales: ${_formatMoney(sales)}\nTotal transactions: $transactionLabel',
                                      child: Container(
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: _chartColors[
                                              index % _chartColors.length],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < chartRows.length; i++)
                      _salesLegendItem(chartRows[i], i),
                  ],
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${rows.length} registered ${_showCashierSales ? 'cashiers' : 'canteens'} - chart shows top 10',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }

  double _salesMetric(Map<String, dynamic> row) => _sort == 'transactions'
      ? (double.tryParse('${row['payment_count']}') ?? 0)
      : (double.tryParse('${row['sales']}') ?? 0);

  Widget _periodButton(String period, String label) {
    final selected = _period == period;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 32,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() => _period = period);
            fetchDashboardData();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? _deepRed : const Color(0xFFF3B6AA),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : _primaryRed,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _salesLegendItem(dynamic raw, int index) {
    final row = Map<String, dynamic>.from(raw as Map);
    final sales = double.tryParse('${row['sales']}') ?? 0;
    final count = int.tryParse('${row['payment_count']}') ?? 0;
    final transactionLabel =
        count == 1 ? '1 transaction' : '$count transactions';
    return SizedBox(
      width: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 8,
              height: 8,
              color: _chartColors[index % _chartColors.length],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '${row['name'] ?? ''}\n${_formatMoney(sales)} / $transactionLabel',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExportSalesTable(List<dynamic> rows) async {
    final category = _showCashierSales ? 'Cashier' : 'Canteen';
    final ranking =
        _sort == 'transactions' ? 'most transactions' : 'highest sales';
    final filter = switch (_period) {
      'today' => 'Today',
      'week' => 'Weekly',
      'month' => 'Monthly',
      'year' => 'Yearly',
      'custom' when _customStart != null && _customEnd != null =>
        '${_dateKey(_customStart!)} to ${_dateKey(_customEnd!)}',
      _ => 'All time',
    };
    final title = '$category $ranking ($filter)';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export sales table?'),
        content: Text('Export "$title" as a CSV file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    String csvField(String value) => '"${value.replaceAll('"', '""')}"';
    final csv = StringBuffer()
      ..writeln(csvField(title))
      ..writeln()
      ..writeln('Name,Total Sales,Total transactions');
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      csv.writeln([
        csvField('${row['name'] ?? ''}'),
        csvField(_formatMoney(double.tryParse('${row['sales']}') ?? 0)),
        csvField('${row['payment_count'] ?? 0}'),
      ].join(','));
    }

    try {
      final fileName = '${category}_${_period}_${_sort}.csv'
          .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      await _exportChannel.invokeMethod<String>('exportCsv', {
        'title': title,
        'fileName': fileName,
        'csv': csv.toString(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('CSV saved to Downloads and ready to share.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not export the sales table.'),
        ));
      }
    }
  }

  Widget _buildNeedsAttention() {
    if (_needsAttention.isEmpty)
      return _whiteMessage('No alerts need attention.');
    final allAlerts = _needsAttention
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList();
    final alerts = allAlerts.where((alert) {
      return _alertFilter == 'all' || alert['type'] == _alertFilter;
    }).toList();
    if (allAlerts.isEmpty) return _whiteMessage('No alerts need attention.');
    final allVisibleSelected = alerts.isNotEmpty && alerts.every(
      (alert) => _selectedAlertKeys.contains(_alertKey(alert)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedAlertKeys.length} of ${alerts.length} selected',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: _isSendingSelectedAlerts ||
                      _isDeletingSelectedAlerts ||
                      alerts.isEmpty
                  ? null
                  : () => setState(() {
                        if (allVisibleSelected) {
                          _selectedAlertKeys.clear();
                        } else {
                          _selectedAlertKeys
                            ..clear()
                            ..addAll(alerts.map(_alertKey));
                        }
                      }),
              child: Text(allVisibleSelected ? 'Clear all' : 'Select all'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _selectedAlertKeys.isEmpty ||
                        _isSendingSelectedAlerts ||
                        _isDeletingSelectedAlerts
                    ? null
                    : _confirmSendSelectedAlerts,
                icon: _isSendingSelectedAlerts
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mail_outline, size: 17),
                label: Text(_isSendingSelectedAlerts
                    ? 'Sending...'
                    : 'Send (${_selectedAlertKeys.length})'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _deepRed,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedAlertKeys.isEmpty ||
                        _isSendingSelectedAlerts ||
                        _isDeletingSelectedAlerts
                    ? null
                    : _confirmDeleteSelectedAlerts,
                icon: _isDeletingSelectedAlerts
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_outline, size: 17),
                label: Text(_isDeletingSelectedAlerts
                    ? 'Deleting...'
                    : 'Delete (${_selectedAlertKeys.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (alerts.isEmpty)
          _whiteMessage('No alerts match this filter.')
        else
          ...alerts.map((alert) {
            final alertKey = _alertKey(alert);
            final isSelected = _selectedAlertKeys.contains(alertKey);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                      color: _cardShadow, blurRadius: 8, offset: Offset(0, 3))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _showAlertDetails(alert),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: _deepRed,
                          visualDensity: VisualDensity.compact,
                          onChanged: _isSendingSelectedAlerts ||
                                  _isDeletingSelectedAlerts
                              ? null
                              : (selected) => setState(() {
                                    if (selected == true) {
                                      _selectedAlertKeys.add(alertKey);
                                    } else {
                                      _selectedAlertKeys.remove(alertKey);
                                    }
                                  }),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${alert['label'] ?? 'Security alert'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text('${alert['name'] ?? 'Account holder'}',
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 11)),
                              Text('${alert['last_at'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.black38, fontSize: 9))
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Email alert',
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD6D2)),
                          onPressed: _isSendingSelectedAlerts ||
                                  _isDeletingSelectedAlerts
                              ? null
                              : () => _confirmSendAlert(alert),
                          icon: const Icon(Icons.mail_outline,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAlertFilterControl() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, color: Colors.white70, size: 20),
          const SizedBox(width: 4),
          DropdownButton<String>(
            value: _alertFilter,
            dropdownColor: Colors.white,
            iconEnabledColor: Colors.white,
            underline: Container(height: 1, color: Colors.white54),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: const [
              DropdownMenuItem(
                value: 'all',
                child: Text('All alerts',
                    style: TextStyle(color: Colors.black87)),
              ),
              DropdownMenuItem(
                value: 'login_failures',
                child: Text('Login failures',
                    style: TextStyle(color: Colors.black87)),
              ),
              DropdownMenuItem(
                value: 'failed_transactions',
                child: Text('Incorrect PIN',
                    style: TextStyle(color: Colors.black87)),
              ),
              DropdownMenuItem(
                value: 'account_setup',
                child: Text('Account setup',
                    style: TextStyle(color: Colors.black87)),
              ),
            ],
            onChanged: _isSendingSelectedAlerts || _isDeletingSelectedAlerts
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _alertFilter = value;
                      _selectedAlertKeys.clear();
                    });
                  },
          ),
        ],
      );

  String _alertKey(Map<String, dynamic> alert) =>
      alert['alert_id'] != null
          ? 'incident:${alert['alert_id']}'
          : '${alert['type']}|${alert['role']}|${alert['source']}|${alert['user_id']}';

  Future<void> _showAlertDetails(Map<String, dynamic> alert) async {
    final type = alert['type']?.toString() ?? '';
    final attempts = int.tryParse(alert['attempts']?.toString() ?? '');
    final explanation = switch (type) {
      'login_failures' =>
        'This alert was triggered after multiple unsuccessful password sign-in attempts within a 24-hour window. It stays pending until the email is sent.',
      'failed_transactions' =>
        'This alert was triggered after multiple incorrect payment or top-up PIN attempts within a 24-hour window. It stays pending until the email is sent.',
      'account_setup' =>
        'This account is still waiting for its initial password setup at least three days after it was created.',
      _ => 'This alert was flagged for administrator review.',
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(alert['label']?.toString() ?? 'Alert details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(explanation),
              const SizedBox(height: 16),
              _alertDetailRow(
                  'Account', alert['name']?.toString() ?? 'Account holder'),
              _alertDetailRow(
                  'Account ID', alert['user_id']?.toString() ?? '-'),
              _alertDetailRow('Account type', alert['role']?.toString() ?? '-'),
              if (attempts != null)
                _alertDetailRow('Attempts', '$attempts for this alert'),
              if (alert['first_at'] != null)
                _alertDetailRow(
                  'First attempt',
                  alert['first_at'].toString(),
                ),
              _alertDetailRow(
                type == 'account_setup' ? 'Account created' : 'Most recent attempt',
                alert['last_at']?.toString() ?? '-',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _alertDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _confirmSendSelectedAlerts() async {
    final selected = _needsAttention
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((alert) => _selectedAlertKeys.contains(_alertKey(alert)))
        .toList();
    if (selected.isEmpty) return;

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send selected email alerts?'),
        content: Text(
          'Send ${selected.length} email${selected.length == 1 ? '' : 's'} to the selected account holders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send emails'),
          ),
        ],
      ),
    );
    if (shouldSend != true || !mounted) return;

    setState(() => _isSendingSelectedAlerts = true);
    var sent = 0;
    final failed = <String>[];
    for (final alert in selected) {
      final key = _alertKey(alert);
      final result = await _sendAlertRequest(alert);
      if (result.sent) {
        sent++;
        _needsAttention.removeWhere((raw) =>
            raw is Map && _alertKey(Map<String, dynamic>.from(raw)) == key);
        _selectedAlertKeys.remove(key);
        if (mounted) setState(() {});
      } else {
        failed.add('${alert['name'] ?? 'Account holder'}: ${result.message}');
      }
    }
    if (!mounted) return;
    setState(() => _isSendingSelectedAlerts = false);
    final message = failed.isEmpty
        ? '$sent email${sent == 1 ? '' : 's'} sent successfully.'
        : '$sent sent, ${failed.length} failed. ${failed.take(2).join('; ')}${failed.length > 2 ? '; …' : ''}. Failed alerts remain selected for retry.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDeleteSelectedAlerts() async {
    final selected = _needsAttention
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((alert) => _selectedAlertKeys.contains(_alertKey(alert)))
        .toList();
    if (selected.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected alerts?'),
        content: Text(
          'Remove ${selected.length} alert${selected.length == 1 ? '' : 's'} from Needs attention? The recorded attempt history will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete alerts'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeletingSelectedAlerts = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('dismiss_admin_security_alerts.php')),
        headers: {
          'Content-Type': 'application/json',
          ...AppSessionService.instance.authorizationHeaders,
        },
        body: json.encode({
          'alerts': selected
              .map((alert) => {
                    'alert_id': alert['alert_id'],
                    'type': alert['type'],
                    'role': alert['role'],
                    'source': alert['source'],
                    'user_id': alert['user_id'],
                  })
              .toList(),
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode != 200 ||
          data is! Map<String, dynamic> ||
          data['status'] != 'success') {
        throw StateError('Could not delete the selected alerts.');
      }

      final removedKeys = selected.map(_alertKey).toSet();
      final dismissed = int.tryParse('${data['dismissed'] ?? 0}') ?? 0;
      final skipped = int.tryParse('${data['skipped'] ?? 0}') ?? 0;
      if (!mounted) return;
      setState(() {
        _needsAttention.removeWhere((raw) =>
            raw is Map &&
            removedKeys.contains(_alertKey(Map<String, dynamic>.from(raw))));
        _selectedAlertKeys.removeAll(removedKeys);
      });
      final message = skipped == 0
          ? '$dismissed alert${dismissed == 1 ? '' : 's'} deleted.'
          : '$dismissed deleted, $skipped already unavailable.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the selected alerts.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeletingSelectedAlerts = false);
    }
  }

  Future<void> _confirmSendAlert(Map<String, dynamic> alert) async {
    final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Send email alert?'),
                content: Text(
                    'Send the security alert email to ${alert['name'] ?? 'this account holder'}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('No')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Send email'))
                ]));
    if (shouldSend != true || !mounted) return;
    final result = await _sendAlertRequest(alert);
    if (result.sent) {
      if (!mounted) return;
      setState(() => _needsAttention.removeWhere((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            return _alertKey(item) == _alertKey(alert);
          }));
      _selectedAlertKeys.remove(_alertKey(alert));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email alert sent.')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<({bool sent, String message})> _sendAlertRequest(
      Map<String, dynamic> alert) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('send_admin_security_alert.php')),
        headers: {
          'Content-Type': 'application/json',
          ...AppSessionService.instance.authorizationHeaders,
        },
        body: json.encode({
          'alert_id': alert['alert_id'],
          'last_attempt_id': alert['last_attempt_id'],
          'type': alert['type'],
          'role': alert['role'],
          'source': alert['source'],
          'user_id': alert['user_id'],
        }),
      );
      final decoded = json.decode(response.body);
      final data = decoded is Map<String, dynamic> ? decoded : null;
      if (response.statusCode == 200 && data?['status'] == 'success') {
        return (sent: true, message: 'Email alert sent.');
      }
      final message = data?['message']?.toString().trim();
      return (
        sent: false,
        message: message == null || message.isEmpty
            ? 'The server could not send the email. Check the server email configuration and logs.'
            : message,
      );
    } catch (_) {
      return (
        sent: false,
        message: 'Could not reach the email service. Check the connection and try again.',
      );
    }
  }

  String _formatActivityTimestamp(dynamic value) {
    final timestamp = value?.toString() ?? '';
    return timestamp.replaceFirst(RegExp(r'\.\d+'), '');
  }

  Widget _whiteMessage(String text) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: const TextStyle(color: Colors.black54)));

  Widget _buildHeroAvatar() {
    return ProfileAvatar(
      role: 'admin',
      userId: widget.id,
      radius: 30,
      fallbackIcon: Icons.person,
      iconColor: Colors.white,
      backgroundColor: Colors.grey,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _mutedText, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatCard() {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () => setState(() => _showUserBreakdown = !_showUserBreakdown),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: math.pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(rotate.value),
              child: child,
            ),
          );
        },
        child: _showUserBreakdown
            ? Container(
                key: const ValueKey('user-breakdown'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(26),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    'admins',
                    'students',
                    'canteens',
                    'cashiers',
                    'parents',
                  ].map((role) {
                    final count = _userBreakdown[role] ?? 0;
                    final label =
                        '${role[0].toUpperCase()}${role.substring(1)}';
                    return SizedBox(
                      height: 13,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  color: _mutedText, fontSize: 9)),
                          Text(_formatNumber(count),
                              style: const TextStyle(
                                  color: _primaryRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('total-users'),
                child: _buildStatCard(
                  icon: Icons.groups_2_outlined,
                  label: 'Total Users',
                  value: _isLoading ? '--' : _formatNumber(_totalUsers),
                ),
              ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        color: _primaryRed,
        child: Container(
          height: 92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(46),
              topRight: Radius.circular(46),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded),
              _buildNavItem(1, Icons.groups_rounded),
              _buildNavItem(2, Icons.query_stats_rounded),
              _buildNavItem(3, Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final selected = _selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? _deepRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 28,
          color: selected ? Colors.white : _primaryRed,
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }

  String _formatMoney(double value) {
    final hasDecimals = value.truncateToDouble() != value;
    final fixed = value.abs().toStringAsFixed(hasDecimals ? 2 : 0);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final formatted = parts.length > 1 ? '$whole.${parts[1]}' : whole;
    final prefix = value < 0 ? '-\u20B1 ' : '\u20B1 ';
    return '$prefix$formatted';
  }
}

class _HorizontalSalesPainter extends CustomPainter {
  final double maximum;
  final bool sortByTransactions;

  const _HorizontalSalesPainter({
    required this.maximum,
    required this.sortByTransactions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const top = 8.0;
    const axisHeight = 25.0;
    final plotWidth = math.max(0.0, size.width - 16).toDouble();
    final plotHeight = math.max(0.0, size.height - top - axisHeight).toDouble();
    final scaleMax = maximum > 0 ? maximum : 1.0;
    final gridPaint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = 0.7;

    for (var tick = 0; tick <= 4; tick++) {
      final x = left + plotWidth * tick / 4;
      canvas.drawLine(Offset(x, top), Offset(x, top + plotHeight), gridPaint);
      final tickValue = scaleMax * tick / 4;
      final label = sortByTransactions
          ? tickValue.toStringAsFixed(0)
          : '\u20B1${tickValue.toStringAsFixed(0)}';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF666666), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(x - text.width / 2, top + plotHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalSalesPainter oldDelegate) {
    if (oldDelegate.maximum != maximum ||
        oldDelegate.sortByTransactions != sortByTransactions) return true;
    return false;
  }
}

class _AdminDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _AdminDateRangePicker({this.initialRange});
  @override
  State<_AdminDateRangePicker> createState() => _AdminDateRangePickerState();
}

class _AdminDateRangePickerState extends State<_AdminDateRangePicker> {
  static const months = [
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
  late DateTime visible;
  DateTime? start, end;
  bool chooseEnd = false;
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  @override
  void initState() {
    super.initState();
    start =
        widget.initialRange == null ? null : day(widget.initialRange!.start);
    end = widget.initialRange == null ? null : day(widget.initialRange!.end);
    final d = start ?? DateTime.now();
    visible = DateTime(d.year, d.month);
  }

  String fmt(DateTime? d) =>
      d == null ? 'Select date' : '${months[d.month - 1]} ${d.day}, ${d.year}';
  void pick(DateTime d) {
    d = day(d);
    setState(() {
      if (!chooseEnd || start == null) {
        start = d;
        end = null;
        chooseEnd = true;
      } else if (d.isBefore(start!)) {
        end = start;
        start = d;
        chooseEnd = false;
      } else {
        end = d;
        chooseEnd = false;
      }
    });
  }

  Future<void> chooseMonthYear() async {
    var m = visible.month, y = visible.year;
    final d = await showDialog<DateTime>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, local) => AlertDialog(
                    title: const Text('Select month and year'),
                    content: Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<int>(
                              value: m,
                              decoration:
                                  const InputDecoration(labelText: 'Month'),
                              items: List.generate(12, (i) => i + 1)
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text(months[v - 1])))
                                  .toList(),
                              onChanged: (v) => local(() => m = v ?? m))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: DropdownButtonFormField<int>(
                              value: y,
                              decoration:
                                  const InputDecoration(labelText: 'Year'),
                              items: List.generate(
                                      101, (i) => DateTime.now().year - 50 + i)
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text('$v')))
                                  .toList(),
                              onChanged: (v) => local(() => y = v ?? y)))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(c, DateTime(y, m)),
                          child: const Text('OK'))
                    ])));
    if (d != null && mounted) setState(() => visible = d);
  }

  @override
  Widget build(BuildContext c) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(c).height * .82,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(child: header('From', start, !chooseEnd)),
                Container(width: 1, height: 68, color: Colors.black12),
                Expanded(child: header('To', end, chooseEnd)),
              ]),
              const Divider(height: 1),
              Expanded(child: calendar()),
              const Divider(height: 1),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: _AdminHomeState._deepRed),
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _AdminHomeState._deepRed,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                  ),
                  onPressed: start != null && end != null
                      ? () => Navigator.pop(
                          c, DateTimeRange(start: start!, end: end!))
                      : null,
                  child: const Text('Apply'),
                ),
              ]),
            ]),
          ),
        ),
      );
  Widget header(String title, DateTime? date, bool active) => InkWell(
      onTap: () => setState(() => chooseEnd = title == 'To'),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(children: [
            Text(title,
                style: TextStyle(
                    color: active ? _AdminHomeState._deepRed : Colors.black54)),
            const SizedBox(height: 4),
            Text(fmt(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? _AdminHomeState._deepRed : Colors.black87))
          ])));
  Widget calendar() {
    final f = DateTime(visible.year, visible.month, 1),
        first = f.subtract(Duration(days: f.weekday - 1)),
        days = List.generate(42, (i) => first.add(Duration(days: i)));
    return Column(children: [
      SizedBox(
          height: 52,
          child: Row(children: [
            IconButton(
                onPressed: () => setState(
                    () => visible = DateTime(visible.year, visible.month - 1)),
                icon: const Icon(Icons.chevron_left)),
            Expanded(
                child: TextButton(
                    onPressed: chooseMonthYear,
                    child: Text('${months[visible.month - 1]}, ${visible.year}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)))),
            IconButton(
                onPressed: () => setState(
                    () => visible = DateTime(visible.year, visible.month + 1)),
                icon: const Icon(Icons.chevron_right))
          ])),
      Row(
          children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((v) => Expanded(
                  child: Center(
                      child: Text(v,
                          style: TextStyle(
                              color: _AdminHomeState._deepRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 11)))))
              .toList()),
      const SizedBox(height: 4),
      Expanded(
          child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisExtent: 44),
              itemBuilder: (c, i) {
                final d = days[i],
                    a = start != null && day(d) == start,
                    b = end != null && day(d) == end,
                    r = start != null &&
                        end != null &&
                        !d.isBefore(start!) &&
                        !d.isAfter(end!),
                    edge = a || b;
                return InkWell(
                    onTap: () => pick(d),
                    child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: edge
                                ? _AdminHomeState._deepRed
                                : r
                                    ? const Color(0xFFF4C1C1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(edge ? 30 : 6)),
                        alignment: Alignment.center,
                        child: Text('${d.day}',
                            style: TextStyle(
                                fontSize: 13,
                                color: edge
                                    ? Colors.white
                                    : d.month == visible.month
                                        ? Colors.black87
                                        : Colors.black38))));
              }))
    ]);
  }
}
