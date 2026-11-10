import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const _red = Color(0xFFE53935);
  static const _ink = Color(0xFF242326);
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 1;
  bool _busy = false;
  bool _showPassword = false;
  String? _token;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _request(String action,
      [Map<String, String> values = const {}]) async {
    final response = await http
        .post(Uri.parse(ApiConfig.url('forgot_password.php')),
            body: {'action': action, ...values})
        .timeout(const Duration(seconds: 15));
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw FormatException(
        response.statusCode == 404
            ? 'Forgot-password service was not found on the server. Restart XAMPP and try again.'
            : 'The server returned HTTP ${response.statusCode} instead of a recovery response.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'The server returned HTTP ${response.statusCode} with an invalid recovery response.',
      );
    }
    return decoded;
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (_busy) return;
    if (_step == 1 && !_email.text.trim().contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_step == 2 && !RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      setState(() => _error = 'Enter the 6-digit verification code.');
      return;
    }
    if (_step == 3) {
      if (_password.text != _confirm.text) {
        setState(() => _error = 'The passwords do not match.');
        return;
      }
      if (_password.text.length < 8 ||
          !RegExp(r'[A-Z]').hasMatch(_password.text) ||
          !RegExp(r'[a-z]').hasMatch(_password.text) ||
          !RegExp(r'\d').hasMatch(_password.text) ||
          !RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_password.text)) {
        setState(() => _error =
            'Use 8-72 characters with uppercase, lowercase, a number, and a special character.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = switch (_step) {
        1 => await _request('send_otp', {'email': _email.text.trim()}),
        2 => await _request('verify_otp', {
            'challenge_token': _token ?? '',
            'code': _otp.text.trim(),
          }),
        3 => await _request('reset_password', {
            'challenge_token': _token ?? '',
            'password': _password.text,
          }),
        _ => <String, dynamic>{'status': 'success'},
      };
      if (!mounted) return;
      if (data['status'] != 'success') {
        final message = data['message']?.toString() ?? '';
        setState(() => _error = message.toLowerCase().contains('no edupocket account')
            ? 'Enter a registered email address.'
            : message.isEmpty
                ? 'Unable to complete this step.'
                : message);
        return;
      }
      setState(() {
        _token = data['challenge_token']?.toString() ?? _token;
        _step = _step < 4 ? _step + 1 : 4;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'The server took too long to respond. Try again.');
      }
    } on SocketException {
      if (mounted) {
        setState(() => _error = 'Could not reach the EduPocket server. Check your connection and try again.');
      }
    } on http.ClientException {
      if (mounted) {
        setState(() => _error = 'Could not reach the EduPocket server. Check your connection and try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Password recovery could not be completed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stepTitle => switch (_step) {
        1 => 'Enter Email Address',
        2 => 'OTP Verification',
        3 => 'Create New Password',
        _ => 'Password Successfully Reset',
      };

  @override
  Widget build(BuildContext context) {
    if (_step == 4) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Column(
        children: [
          Container(
            height: 245,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/BG.png'), fit: BoxFit.cover),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const Spacer(),
                  Image.asset('assets/logo.png', height: 76),
                  const SizedBox(height: 8),
                  const Text('Secure your EduPocket account',
                      style: TextStyle(color: Colors.white, fontSize: 17)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_step == 4 ? 'Password Updated' : 'Step $_step of 4',
                          style: const TextStyle(color: _red, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(_stepTitle,
                          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: _ink)),
                      const SizedBox(height: 8),
                      Text(_description,
                          style: const TextStyle(color: Color(0xFF77747A), height: 1.4, fontSize: 15)),
                      const SizedBox(height: 28),
                      if (_step == 1) ...[
                        _label('Registered Email Address'),
                        _field(_email, 'Email address', Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress),
                      ] else if (_step == 2) ...[
                        _label('One-Time Password (OTP)'),
                        _field(_otp, 'Enter 6-digit OTP', Icons.pin_outlined,
                            keyboardType: TextInputType.number),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _busy ? null : () async {
                              setState(() { _busy = true; _error = null; });
                              try {
                                final data = await _request('send_otp', {'email': _email.text.trim()});
                                if (!mounted) return;
                                if (data['status'] == 'success') {
                                  setState(() => _token = data['challenge_token']?.toString() ?? _token);
                                } else {
                                  setState(() => _error = data['message']?.toString());
                                }
                              } catch (_) {
                                if (mounted) setState(() => _error = 'Unable to resend the code.');
                              } finally { if (mounted) setState(() => _busy = false); }
                            },
                            child: const Text('Resend OTP'),
                          ),
                        ),
                      ] else if (_step == 3) ...[
                        _label('New Password'),
                        _field(_password, 'New password', Icons.lock_outline,
                            obscure: !_showPassword,
                            suffix: IconButton(
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            )),
                        const SizedBox(height: 8),
                        const Text(
                          'Use 8-72 characters with an uppercase letter, lowercase letter, number, and special symbol.',
                          style: TextStyle(
                            color: Color(0xFF6F6871),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _label('Confirm New Password'),
                        _field(_confirm, 'Confirm password', Icons.lock_outline,
                            obscure: !_showPassword),
                      ] else ...[
                        const SizedBox(height: 28),
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF18A765), size: 64),
                        const SizedBox(height: 16),
                        const Text('Your password was successfully updated. You can now log in with your new password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF77747A), height: 1.5, fontSize: 16)),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: _red)),
                      ],
                      const SizedBox(height: 28),
                      if (_step < 4)
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: _busy
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(_step == 1 ? 'Send OTP' : _step == 2 ? 'Verify OTP' : 'Reset Password',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        )
                      else
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login')),
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

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Image.asset('assets/redlogo.png', height: 64),
            const SizedBox(height: 22),
            const Text(
              'Password Reset',
              style: TextStyle(
                color: Color(0xFFC51F26),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFC51F26),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(64)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 46, 24, 32),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFD98989),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Color(0xFF299B0A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 46,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'Password Reset Successfully',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF24C34A),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Your password has been updated.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF454545),
                                fontSize: 16,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 300,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFC51F26),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  String get _description => switch (_step) {
        1 => 'Enter the email address linked to your EduPocket account. We’ll send you a verification code to reset your password.',
        2 => 'We sent a 6-digit verification code to your registered email address. Enter it below to continue.',
        3 => 'Your email has been verified. Create a new password for your EduPocket account.',
        _ => 'Your password has been successfully updated. You can now log in using your new password.',
      };

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
      );

  Widget _field(TextEditingController controller, String hint, IconData icon,
      {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: _red),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF7F7F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      );
}
