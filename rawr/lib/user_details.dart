import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserDetails extends StatelessWidget {
  final Map<String, dynamic> user;
  final String category;

  const UserDetails({Key? key, required this.user, required this.category})
      : super(key: key);

  Icon _getIcon(String label) {
    switch (label.toLowerCase()) {
      case 'name':
        return const Icon(Icons.person, color: Colors.white);
      case 'student number':
      case 'parent id':
      case 'canteen id':
        return const Icon(Icons.badge, color: Colors.white);
      case 'linked parent':
      case 'linked student':
        return const Icon(Icons.link, color: Colors.white);
      case 'balance':
        return const Icon(Icons.account_balance_wallet, color: Colors.white);
      case 'location':
        return const Icon(Icons.location_on, color: Colors.white);
      case 'canteen name':
        return const Icon(Icons.store, color: Colors.white);
      default:
        return const Icon(Icons.info, color: Colors.white);
    }
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _getIcon(label),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(BuildContext context) async {
    final TextEditingController nameController =
        TextEditingController(text: user['name'] ?? '');
    final TextEditingController locationController =
        TextEditingController(text: user['location'] ?? '');
    final TextEditingController linkedController = TextEditingController(
        text: category == 'student'
            ? (user['parent_name'] ?? '')
            : (user['student_name'] ?? ''));
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController pinController = TextEditingController(
        text: category == 'student' ? (user['pin'] ?? '') : '');

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (category == 'pos')
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                if (category == 'student' || category == 'parent')
                  TextField(
                    controller: linkedController,
                    decoration: InputDecoration(
                      labelText: category == 'student'
                          ? 'Linked Parent ID'
                          : 'Linked Student ID',
                    ),
                  ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (category == 'student')
                  TextField(
                    controller: pinController,
                    decoration: const InputDecoration(labelText: 'PIN'),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final id = category == 'student'
                    ? user['student_num']
                    : category == 'parent'
                        ? user['parent_id']
                        : user['canteen_id'];

                final body = {
                  'category': category,
                  'id': id,
                  'Fname': nameController.text,
                  'linked_id': linkedController.text,
                  'location': locationController.text,
                  'password': passwordController.text,
                  'pin': category == 'student' ? pinController.text : '',
                };

                try {
                  final response = await http.post(
                    Uri.parse('http://10.104.13.218:8000/koyah_nabago.php'),
                    body: body,
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully!'),
                      ),
                    );
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating user: ${response.body}'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('http://10.104.13.218:8000/koyah_natanggarl.php'),
        body: {
          'category': category,
          'id': category == 'student'
              ? user['student_num']
              : category == 'parent'
                  ? user['parent_id']
                  : user['canteen_id'],
        },
      );

      final data = response.body;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User deleted successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> details = [];

    if (category == 'student') {
      details = [
        _buildDetailCard('Name', user['name'] ?? ''),
        _buildDetailCard('Student Number', user['student_num'] ?? ''),
        _buildDetailCard('Linked Parent', user['parent_name'] ?? 'None'),
        _buildDetailCard(
          'Balance',
          user['balance'] != null
              ? '₱${double.tryParse(user['balance'].toString())?.toStringAsFixed(2) ?? '0.00'}'
              : '₱0.00',
        ),
      ];
    } else if (category == 'parent') {
      details = [
        _buildDetailCard('Name', user['name'] ?? ''),
        _buildDetailCard('Parent ID', user['parent_id'] ?? ''),
        _buildDetailCard('Linked Student', user['student_name'] ?? 'None'),
      ];
    } else if (category == 'pos') {
      details = [
        _buildDetailCard('Canteen Name', user['name'] ?? ''),
        _buildDetailCard('Canteen ID', user['canteen_id'] ?? ''),
        _buildDetailCard('Location', user['location'] ?? 'Not set'),
      ];
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 251, 251),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromARGB(255, 134, 23, 23),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Image.asset('assets/redlogo.png', height: 40),
                  const SizedBox(width: 12),
                  const Text(
                    'User Details',
                    style: TextStyle(
                      color: Color.fromARGB(255, 134, 23, 23),
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
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 196, 25, 25),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  ...details,
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        Icons.edit,
                        'Edit',
                        _editUser,
                      ),
                      _buildActionButton(
                        context,
                        Icons.delete,
                        'Delete',
                        _deleteUser,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    void Function(BuildContext) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 134, 23, 23)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color.fromARGB(255, 134, 23, 23),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
