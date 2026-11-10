import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'app_session_service.dart';
import 'login.dart';

class ChangePasswordPage extends StatefulWidget {
  final String id;
  final String role;
  final String currentPassword;

  const ChangePasswordPage({
    super.key,
    required this.id,
    required this.role,
    required this.currentPassword,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isSaving = false;

  static const Color primaryRed = Color(0xFFE53935);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color lightRed = Color(0xFFFFEEEE);
  static const Color fieldColor = Color(0xFFF7F7F7);

  bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (isSaving) return;

    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    if (!isStrongPassword(newPassword)) {
      showMessage(
        "Password must have 8+ characters, uppercase, lowercase, number, and special character",
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('change_password.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: {
          "id": widget.id,
          "role": widget.role,
          "current_password": widget.currentPassword,
          "password": newPassword,
        },
      ).timeout(const Duration(seconds: 8));

      await AppSessionService.instance.handleResponse(response);

      if (!mounted) return;

      if (response.statusCode != 200) {
        showMessage("Server error: ${response.statusCode}");
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }

      final data = decoded;

      if (data['status'] == 'success') {
        showMessage("Password changed successfully");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      } else {
        showMessage(
          data['message']?.toString() ?? 'Unable to save credentials',
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      showMessage("The server took too long to respond");
    } on FormatException {
      if (!mounted) return;
      showMessage("The server returned an invalid response");
    } catch (e) {
      if (!mounted) return;
      showMessage("Could not save the new credentials");
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: darkRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryRed),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldColor,
      counterText: "",
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primaryRed,
          width: 1.5,
        ),
      ),
    );
  }

  Widget sectionHeading(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: lightRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: !isSaving,
      decoration: fieldDecoration(
        label: label,
        icon: icon,
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/BG.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 25),
                          Image.asset(
                            'assets/logo.png',
                            height: 95,
                            semanticLabel: 'EduPocket',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Secure your EduPocket account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Arial',
                            ),
                          ),
                          const SizedBox(height: 30),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 28,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 480,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Set Up Your Account',
                                        style: TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Create your personal login credentials to get started.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      sectionHeading(
                                        'New Password',
                                        'Create a strong password',
                                        Icons.lock_outline,
                                      ),
                                      const SizedBox(height: 18),
                                      passwordField(
                                        label: 'New Password',
                                        controller: newPasswordController,
                                        obscure: obscurePassword,
                                        icon: Icons.lock_outline,
                                        toggle: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 15),
                                      passwordField(
                                        label: 'Confirm Password',
                                        controller: confirmPasswordController,
                                        obscure: obscureConfirmPassword,
                                        icon: Icons.lock_outline,
                                        toggle: () {
                                          setState(() {
                                            obscureConfirmPassword =
                                                !obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 22),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: lightRed,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: primaryRed,
                                              size: 20,
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Your password must have at least 8 characters, uppercase and lowercase letters, a number, and a special character. You can set or change your payment PIN later in your account settings.',
                                                style: TextStyle(
                                                  color: darkRed,
                                                  fontSize: 12,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed:
                                              isSaving ? null : changePassword,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryRed,
                                            disabledBackgroundColor:
                                                const Color(0xFFE2B9BA),
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                          ),
                                          child: isSaving
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 9),
                                                    Text(
                                                      'Save Credentials',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
