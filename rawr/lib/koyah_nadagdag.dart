import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddUser extends StatefulWidget {
  final String category;
  const AddUser({super.key, required this.category});

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();

    if (widget.category == 'student') {
      controllers['name'] = TextEditingController();
      controllers['student_num'] = TextEditingController();
      controllers['parent_id'] = TextEditingController();
      controllers['balance'] = TextEditingController();
      controllers['password'] = TextEditingController();
    } else if (widget.category == 'parent') {
      controllers['name'] = TextEditingController();
      controllers['parent_id'] = TextEditingController();
      controllers['linked_student'] = TextEditingController();
      controllers['email'] = TextEditingController();
      controllers['password'] = TextEditingController();
    } else if (widget.category == 'pos') {
      controllers['name'] = TextEditingController();
      controllers['canteen_id'] = TextEditingController();
      controllers['location'] = TextEditingController();
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
        Uri.parse('http://10.104.13.218:8000/koyah_nadagdag.php'),
        body: body,
      );

      print('POST body: $body');
      print('Response code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildTextField(String label, {bool required = true}) {
    bool isPassword = label == 'password' && widget.category == 'student';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controllers[label],
        validator: required
            ? (val) => val == null || val.isEmpty ? 'Required' : null
            : null,
        obscureText: isPassword, // hide text for password
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                  const SizedBox(width: 12),
                  Image.asset('assets/redlogo.png', height: 40),
                  const SizedBox(width: 12),
                  Text(
                    'Add $displayCategory',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 196, 25, 25),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Pass `required: false` for optional fields
                    ...controllers.keys.map((key) {
                      bool isRequired = true;

                      if ((widget.category == 'student' &&
                              (key == 'parent_id' || key == 'balance')) ||
                          (widget.category == 'parent' &&
                              key == 'linked_student') ||
                          (widget.category == 'pos' && key == 'location')) {
                        isRequired = false;
                      }
                      return _buildTextField(key, required: isRequired);
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 134, 23, 23),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add $displayCategory',
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
