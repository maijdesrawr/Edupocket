import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'app_session_service.dart';
import 'api_config.dart';

class AddUser extends StatefulWidget {
  final String category;
  const AddUser({super.key, required this.category});

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};

  List<Map<String, dynamic>> parents = [];
  String? selectedParentId;
  bool isLoadingParents = false;
  bool _isLookingUpStudent = false;

  @override
  void dispose() {
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.category == 'student') {
      controllers['student_first_name'] = TextEditingController();
      controllers['student_middle_name'] = TextEditingController();
      controllers['student_last_name'] = TextEditingController();
      controllers['student_suffix'] = TextEditingController();
      controllers['student_num'] = TextEditingController();
      controllers['student_email'] = TextEditingController();

      controllers['parent_first_name'] = TextEditingController();
      controllers['parent_middle_name'] = TextEditingController();
      controllers['parent_last_name'] = TextEditingController();
      controllers['parent_suffix'] = TextEditingController();
    } else if (widget.category == 'child') {
      controllers['parent_id'] = TextEditingController();

      controllers['student_first_name'] = TextEditingController();
      controllers['student_middle_name'] = TextEditingController();
      controllers['student_last_name'] = TextEditingController();
      controllers['student_suffix'] = TextEditingController();
      controllers['student_num'] = TextEditingController();
      controllers['student_email'] = TextEditingController();
    } else if (widget.category == 'pos') {
      controllers['name'] = TextEditingController();
      controllers['canteen_id'] = TextEditingController();
      controllers['location'] = TextEditingController();
      controllers['password'] = TextEditingController();
    } else if (widget.category == 'cashier') {
      controllers['name'] = TextEditingController();
      controllers['cashier_id'] = TextEditingController();
      controllers['username'] = TextEditingController();
      controllers['password'] = TextEditingController();
    }

    if (widget.category == 'child') {
      _loadParents();
    }
  }

  Future<void> _loadParents() async {
    if (widget.category != 'child') return;

    setState(() {
      isLoadingParents = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('koyah_nadagdag.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: {
          'action': 'get_parents',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            parents = List<Map<String, dynamic>>.from(
              data['parents'] ?? [],
            );
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message'] ?? 'Failed to load parents.',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load existing parents.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading parents: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingParents = false;
        });
      }
    }
  }

  String formatLabel(String key) {
    if (key == 'student_num') return 'Student Number';
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String? getHelperText(String label) {
    switch (label) {
      case 'student_first_name':
        return 'Example: Juan or Juan Joseph';

      case 'student_middle_name':
        return 'Optional';

      case 'student_last_name':
        return 'Example: Dela Cruz';

      case 'student_suffix':
        return 'Optional (Jr., Sr., III)';

      case 'student_num':
        return 'Scan the student QR to automatically load the record';

      case 'student_email':
        return 'Uses the existing UE mailbox';

      case 'parent_id':
        return 'Existing Parent ID';

      case 'parent_first_name':
        return 'Example: Maria or Maria Sofia';

      case 'parent_middle_name':
        return 'Optional';

      case 'parent_last_name':
        return 'Example: Santos';

      case 'parent_suffix':
        return 'Optional (Jr., Sr., III)';

      case 'name':
        return 'Example: Main Canteen';

      case 'canteen_id':
        return 'Example: CAN001';

      case 'location':
        return 'Example: Building A';

      case 'cashier_id':
        return 'Example: CASH001';

      case 'username':
        return 'Example: cashier01';

      case 'password':
        return 'Enter temporary password';

      default:
        return null;
    }
  }

  Future<void> _scanStudentQr() async {
    final qrValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var captured = false;
        return AlertDialog(
          title: const Text('Scan student QR'),
          content: SizedBox(
            width: 320,
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                onDetect: (capture) {
                  if (captured) return;
                  for (final barcode in capture.barcodes) {
                    final value = barcode.rawValue?.trim() ?? '';
                    if (value.isEmpty) continue;
                    captured = true;
                    Navigator.of(dialogContext).pop(value);
                    break;
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (qrValue == null || !mounted) return;

    setState(() => _isLookingUpStudent = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('koyah_nadagdag.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: {
          'action': 'lookup_dummy_student',
          'qr_value': qrValue,
        },
      ).timeout(const Duration(seconds: 12));
      if (await AppSessionService.instance.handleResponse(response)) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final student = data['student'];
      if (response.statusCode != 200 ||
          data['status'] != 'success' ||
          student is! Map) {
        throw FormatException(
          (data['message'] ?? 'This QR is not in the dummy student roster.')
              .toString(),
        );
      }

      controllers['student_num']!.text =
          (student['student_num'] ?? '').toString();
      controllers['student_first_name']!.text =
          (student['first_name'] ?? '').toString();
      controllers['student_middle_name']!.text =
          (student['middle_name'] ?? '').toString();
      controllers['student_last_name']!.text =
          (student['last_name'] ?? '').toString();
      controllers['student_suffix']!.text =
          (student['suffix'] ?? '').toString();
      controllers['student_email']!.text = (student['email'] ?? '').toString();
      if (controllers.containsKey('parent_first_name')) {
        controllers['parent_first_name']!.text =
            (student['parent_first_name'] ?? '').toString();
        controllers['parent_middle_name']!.text =
            (student['parent_middle_name'] ?? '').toString();
        controllers['parent_last_name']!.text =
            (student['parent_last_name'] ?? '').toString();
        controllers['parent_suffix']!.text =
            (student['parent_suffix'] ?? '').toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student roster record loaded.')),
        );
      }
    } on FormatException catch (error) {
      if (mounted && error.message.toLowerCase().contains('already exists')) {
        await _showAccountCreationResult(
          success: false,
          message: 'Already existing user.',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR scanned.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the scanned student.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLookingUpStudent = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final body = {'category': widget.category};

      controllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          body[key] = controller.text.trim();
        }
      });

      final response = await http.post(
        Uri.parse(ApiConfig.url('koyah_nadagdag.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          if (widget.category == 'pos' || widget.category == 'cashier') {
            if (!mounted) return;
            await showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                      title: const Text('Success'),
                      content: Text(data['message']?.toString() ??
                          'Account created successfully.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Done'))
                      ],
                    ));
            if (mounted) Navigator.pop(context, true);
            return;
          }
          await _showAccountCreationResult(
            success: true,
            message: widget.category == 'child'
                ? 'You have successfully linked the Student account to a Parent.'
                : 'You have successfully created a Student and Parent account.',
          );
        } else {
          final message = data['error_code'] == 'email_delivery_failed'
              ? 'The email does not exist. Please try again later.'
              : _accountCreationErrorMessage(data['message']?.toString());
          if (widget.category == 'student' || widget.category == 'child') {
            await _showAccountCreationResult(success: false, message: message);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        }
      } else {
        String message = 'The account could not be created.';
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            message = data['error_code'] == 'email_delivery_failed'
                ? 'The email does not exist. Please try again later.'
                : _accountCreationErrorMessage(data['message']?.toString());
          }
        } catch (_) {}
        if (widget.category == 'student' || widget.category == 'child') {
          await _showAccountCreationResult(success: false, message: message);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (e) {
      if (widget.category == 'student' || widget.category == 'child') {
        await _showAccountCreationResult(
          success: false,
          message: 'Could not connect to the server. Please try again.',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _accountCreationErrorMessage(String? message) {
    final normalized = (message ?? '').toLowerCase();
    if (normalized.contains('already exists') ||
        normalized.contains('already registered')) {
      return 'Already existing user.';
    }
    return message == null || message.trim().isEmpty
        ? 'The account could not be created.'
        : message;
  }

  Future<void> _showAccountCreationResult({
    required bool success,
    required String message,
  }) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AccountCreationResultScreen(
          success: success,
          message: message,
        ),
      ),
    );
    if (success && completed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildTextField(String label, {bool required = true}) {
    bool isPassword = (label == 'password');
    final isStudentField = label.startsWith('student_');
    final isLoadedParentField =
        widget.category == 'student' && label.startsWith('parent_');
    final isQrPopulatedField =
        (widget.category == 'student' || widget.category == 'child') &&
            (isStudentField || isLoadedParentField);

    bool isNumericOnly = label == 'student_num' ||
        label == 'parent_id' ||
        label == 'linked_student';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: AbsorbPointer(
        absorbing: isQrPopulatedField,
        child: TextFormField(
        controller: controllers[label],
        enabled: !isLoadedParentField,
        readOnly: isStudentField || isLoadedParentField,
        enableInteractiveSelection: !isLoadedParentField,
        showCursor: !isLoadedParentField,
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required' : null
            : null,
        obscureText: isPassword,
        keyboardType: isNumericOnly ? TextInputType.number : null,
        inputFormatters: isNumericOnly
            ? [
                FilteringTextInputFormatter.digitsOnly,
                if (label == 'student_num' || label == 'parent_id')
                  LengthLimitingTextInputFormatter(11),
              ]
            : null,
        style: const TextStyle(color: Color(0xFFC51F26), fontSize: 14),
        decoration: InputDecoration(
          labelText: formatLabel(label),
          helperText: null,
          errorStyle: const TextStyle(
            color: Color(0xFFFFD7D7),
            fontSize: 12,
          ),
          labelStyle: const TextStyle(color: Color(0xFFC51F26), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFFFF9E8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          suffixIcon: null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFD94A4A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFD94A4A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFB90000), width: 1.5),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildParentDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: selectedParentId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Parent ID',
          helperText: null,
          labelStyle: const TextStyle(color: Color(0xFFC51F26), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFFFF9E8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFD94A4A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFD94A4A)),
          ),
        ),
        dropdownColor: const Color(0xFFFFF9E8),
        hint: const Text(
          'Select Parent',
          style: const TextStyle(color: Color(0xFFC51F26)),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Colors.black,
          size: 32,
        ),
        style: const TextStyle(color: Color(0xFFC51F26)),
        items: parents.map((parent) {
          final parentId = parent['parent_id'].toString();

          final firstName = parent['first_name']?.toString() ?? '';
          final lastName = parent['last_name']?.toString() ?? '';
          final fullName = [
            firstName,
            lastName,
          ].where((name) => name.trim().isNotEmpty).join(' ');

          return DropdownMenuItem<String>(
            value: parentId,
            child: Text(
              '$parentId - $fullName',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: isLoadingParents
            ? null
            : (value) {
                setState(() {
                  selectedParentId = value;
                  controllers['parent_id']!.text = value ?? '';
                });
              },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a parent';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCategory =
        '${widget.category[0].toUpperCase()}${widget.category.substring(1)}';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 251, 251),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            color: const Color.fromARGB(255, 255, 255, 255),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromARGB(255, 199, 42, 42),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 2),
                  Image.asset('assets/redlogo.png', height: 30),
                  const SizedBox(width: 8),
                  Text(
                    'Add ${widget.category == 'child' ? 'Student' : displayCategory}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: const BoxDecoration(
                color: const Color(0xFFC51F26),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (widget.category == 'student' ||
                        widget.category == 'child') ...[
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLookingUpStudent ? null : _scanStudentQr,
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text('Scan QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFC51F26),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    ...controllers.keys.map((key) {
                      if (widget.category == 'child' && key == 'parent_id') {
                        return _buildParentDropdown();
                      }

                      bool isRequired = true;

                      if (key.contains('middle_name') ||
                          key.contains('suffix') ||
                          (widget.category == 'student' &&
                              key == 'parent_id') ||
                          (widget.category == 'parent' &&
                              key == 'linked_student') ||
                          (widget.category == 'pos' && key == 'location') ||
                          (widget.category == 'cashier' &&
                              key == 'canteen_id')) {
                        isRequired = false;
                      }

                      return _buildTextField(
                        key,
                        required: isRequired,
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 134, 23, 23),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        'Add ${widget.category == 'child' ? 'Student' : displayCategory}',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 196, 25, 25),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    );
  }
}

class _AccountCreationResultScreen extends StatelessWidget {
  final bool success;
  final String message;

  const _AccountCreationResultScreen({
    required this.success,
    required this.message,
  });

  static const _red = Color(0xFFC51F26);
  static const _deepRed = Color(0xFFB90000);

  @override
  Widget build(BuildContext context) {
    final statusColor =
        success ? const Color(0xFF24C34A) : const Color(0xFFFF4148);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Image.asset('assets/redlogo.png', height: 64),
            const SizedBox(height: 22),
            const Text(
              'Account Creation',
              style: TextStyle(
                color: _red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(64)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
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
                              decoration: BoxDecoration(
                                color: success
                                    ? const Color(0xFF299B0A)
                                    : _deepRed,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                success ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 46,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Text(
                              success
                                  ? 'Successfully Created Account'
                                  : 'Failed to Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                        onPressed: () => Navigator.pop(context, success),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _red,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          success ? 'Done' : 'Try Again',
                          style: const TextStyle(
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
            Container(
              height: 76,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(42)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.home_outlined, color: _red, size: 28),
                  Icon(Icons.history, color: _red, size: 28),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _red,
                    child: Icon(Icons.qr_code, color: Colors.white, size: 25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
