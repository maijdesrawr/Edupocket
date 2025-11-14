import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  final String recipientNumber;
  final String paymentTitle;

  const PaymentScreen({
    Key? key,
    required this.recipientNumber,
    required this.paymentTitle,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _amount = '';
  String _pin = '';
  bool _isEnteringAmount = true;
  bool _isLoading = false;

  void _addAmountDigit(String digit) {
    setState(() {
      if (digit == '.' && !_amount.contains('.')) {
        if (_amount.isEmpty) {
          _amount = '0.';
        } else {
          _amount += digit;
        }
      } else if (digit != '.' && _amount.length < 10) {
        if (_amount == '0') {
          _amount = digit;
        } else {
          _amount += digit;
        }
      }
    });
  }

  void _removeAmountDigit() {
    setState(() {
      if (_amount.isNotEmpty)
        _amount = _amount.substring(0, _amount.length - 1);
    });
  }

  void _addPinDigit(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
      });

      if (_pin.length == 6) {
        _submitPayment();
      }
    }
  }

  void _removePinDigit() {
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPayment() async {
    setState(() => _isLoading = true);
    final url = Uri.parse("http://10.104.13.218:8000/confirm_payment.php");

    try {
      final response = await http.post(url, body: {
        'student_num': widget.recipientNumber,
        'pin': _pin,
        'amount': _amount,
        'description': widget.paymentTitle,
      });

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        _showDialog(
          title: 'Payment Successful',
          message:
              '₱${_amount} has been deducted from your account.\n\nNew Balance: ₱${data['new_balance']}',
          isError: false,
        );
      } else {
        _showDialog(
          title: 'Error',
          message: data['message'] ?? 'Something went wrong.',
          isError: true,
        );
      }
    } catch (e) {
      _showDialog(
        title: 'Connection Error',
        message: 'Could not reach the server.\n\nError: $e',
        isError: true,
      );
    }

    setState(() => _isLoading = false);
  }

  void _showDialog(
      {required String title, required String message, required bool isError}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(color: isError ? Colors.red : Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!isError)
                Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Image.asset('assets/icons/logo-red.png', height: 60),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFAC2324)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnteringAmount ? 'Enter Amount' : 'Enter PIN',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFAC2324)),
                        ),
                        const SizedBox(height: 16),
                        _buildStudentInfo(), // <- Student info
                        const SizedBox(height: 16),
                        _isEnteringAmount
                            ? _buildAmountCard()
                            : _buildPinCard(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildKeypad(),
              const SizedBox(height: 16),
              _isEnteringAmount
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: _amount.isEmpty || _amount == '0.'
                            ? null
                            : () {
                                setState(() {
                                  _isEnteringAmount = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAC2324),
                          disabledBackgroundColor: Colors.grey[300],
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Next',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 80),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFAC2324), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/user-circle-single.png',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.recipientNumber,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFAC2324), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount To Pay',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Text('₱${_amount.isEmpty ? '0' : _amount}',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAC2324))),
        ],
      ),
    );
  }

  Widget _buildPinCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Paying ₱${_amount.isEmpty ? '0' : _amount}',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            bool isFilled = index < _pin.length;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isFilled ? const Color(0xFFAC2324) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFAC2324), width: 2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final buttons = _isEnteringAmount
        ? [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['.', '0', 'DEL']
          ]
        : [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['FORGOT', '0', 'DEL']
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: buttons.expand((row) {
          return row.map((btn) {
            return GestureDetector(
              onTap: () {
                if (btn == 'DEL') {
                  _isEnteringAmount ? _removeAmountDigit() : _removePinDigit();
                } else if (btn == 'FORGOT') {
                  if (!_isEnteringAmount) print('Forgot PIN pressed');
                } else {
                  _isEnteringAmount ? _addAmountDigit(btn) : _addPinDigit(btn);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isEnteringAmount
                      ? const Color(0xFFAC2324)
                      : Colors.transparent,
                  border: Border.all(color: Colors.white.withAlpha(128)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: btn == 'DEL'
                      ? Icon(Icons.backspace_outlined,
                          color: _isEnteringAmount
                              ? Colors.white
                              : const Color(0xFFAC2324))
                      : Text(btn,
                          style: TextStyle(
                              fontSize: btn == 'FORGOT' ? 12 : 24,
                              fontWeight: FontWeight.w600,
                              color: _isEnteringAmount
                                  ? Colors.white
                                  : const Color(0xFFAC2324))),
                ),
              ),
            );
          }).toList();
        }).toList(),
      ),
    );
  }
}
