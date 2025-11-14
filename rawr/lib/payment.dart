import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletPage extends StatefulWidget {
  final String userName;
  final String userId;
  final String selectedChildId;
  final String selectedChildName;
  final double amount;

  const WalletPage({
    super.key,
    required this.userName,
    required this.userId,
    required this.selectedChildId,
    required this.selectedChildName,
    required this.amount,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool loading = false;

  Future<void> _submitTopUp() async {
    setState(() => loading = true);

    final url = Uri.parse('http://10.104.13.218:8000/record_topup.php');

    try {
      final response = await http.post(
        url,
        body: {
          'parent_id': widget.userId,
          'child_id': widget.selectedChildId,
          'amount': widget.amount.toString(),
          'method': 'Bank',
        },
      );

      setState(() => loading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Top-up successful! New balance: Php ${data['new_balance']}',
              ),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${data['message']}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Page'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Parent: ${widget.userName}'),
                  Text('Child: ${widget.selectedChildName}'),
                  Text('Amount: Php ${widget.amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitTopUp,
                    child: const Text('Confirm Top-Up'),
                  ),
                ],
              ),
      ),
    );
  }
}
