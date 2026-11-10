import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'app_session_service.dart';

class UserDetails extends StatelessWidget {
  final Map<String, dynamic> user;
  final String category;

  const UserDetails({super.key, required this.user, required this.category});

  Icon _getIcon(String label) {
    switch (label.toLowerCase()) {
      case 'name':
        return const Icon(Icons.person, color: Colors.white);
      case 'student number':
      case 'parent id':
      case 'canteen id':
      case 'cashier id':
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
      case 'username':
        return const Icon(Icons.account_circle, color: Colors.white);
      default:
        return const Icon(Icons.info, color: Colors.white);
    }
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withValues(alpha: 0.2),
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
    final nameController = TextEditingController(text: user['name'] ?? '');
    final locationController =
        TextEditingController(text: user['location'] ?? '');
    final linkedController = TextEditingController(
        text: category == 'student'
            ? (user['parent_id'] ?? '')
            : (user['student_nums'] ?? user['student_num'] ?? ''));
    final usernameController =
        TextEditingController(text: user['username'] ?? '');
    final canteenController =
        TextEditingController(text: user['canteen_id'] ?? '');

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
                  readOnly: false,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    fillColor: Colors.black12,
                  ),
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
                          : 'Linked Student IDs (comma separated)',
                    ),
                  ),
                if (category == 'cashier')
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                if (category == 'student') {
                  final studentNum = user['student_num'] ?? '';

                  if (studentNum.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Student Number is required')),
                    );
                    return;
                  }

                  if (!RegExp(r'^[A-Za-z0-9_-]{1,20}$')
                      .hasMatch(user['student_num'] ?? '')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid student number')),
                    );
                    return;
                  }
                }

                final id = category == 'student'
                    ? user['student_num']
                    : category == 'parent'
                        ? user['parent_id']
                        : category == 'pos'
                            ? user['canteen_id']
                            : user['cashier_id'];

                final body = {
                  'category': category,
                  'id': id,
                  'Fname': nameController.text,
                  'location': locationController.text,
                  'username':
                      category == 'cashier' ? usernameController.text : '',
                  'canteen_id':
                      category == 'cashier' ? canteenController.text : '',
                };

                if (category == 'student' || category == 'parent') {
                  body['linked_id'] = linkedController.text.trim();
                }
                try {
                  final response = await http.post(
                    Uri.parse(ApiConfig.url('koyah_nabago.php')),
                    headers: AppSessionService.instance.authorizationHeaders,
                    body: body,
                  );

                  if (!context.mounted) return;
                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    final status = data['status'] ?? 'error';
                    final message = data['message'] ?? 'Unknown error';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );

                    if (status == 'success') {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('HTTP Error: ${response.statusCode}')),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
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
        content: const Text(
            'Delete this account permanently? The account will be removed, and its transaction history and receipts will be retained. This cannot be undone.'),
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
      final id = category == 'student'
          ? user['student_num']
          : category == 'parent'
              ? user['parent_id']
              : category == 'pos'
                  ? user['canteen_id']
                  : user['cashier_id'];

      final response = await http.post(
        Uri.parse(ApiConfig.url('account_delete.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: {
          'category': category,
          'id': id,
        },
      );
      if (!context.mounted) return;

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (data['message'] ?? 'User deleted successfully!').toString(),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (data['message'] ?? 'The user could not be deleted.').toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleStudentLock(BuildContext context) async {
    final isLocked = user['is_locked'] == 1 ||
        user['is_locked'] == '1' ||
        user['is_locked'] == true;

    final action = isLocked ? 'unlock' : 'lock';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(isLocked ? 'Unlock Student Account' : 'Lock Student Account'),
        content: Text(
          isLocked
              ? 'Are you sure you want to unlock this student account?'
              : 'Are you sure you want to lock this student account? The student will no longer be able to access their account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isLocked ? 'Unlock' : 'Lock',
              style: TextStyle(
                color: isLocked ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('student_manual_lock.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: {
          'student_num': user['student_num'].toString(),
          'action': action,
        },
      );

      if (!context.mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Account status updated.'),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(data['message'] ?? 'Failed to update account status.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
              ? '\u20B1${double.tryParse(user['balance'].toString())?.toStringAsFixed(2) ?? '0.00'}'
              : '\u20B10.00',
        ),
      ];
    } else if (category == 'parent') {
      details = [
        _buildDetailCard('Name', user['name'] ?? ''),
        _buildDetailCard('Parent ID', user['parent_id'] ?? ''),
        _buildDetailCard('Linked Students', user['student_name'] ?? 'None'),
      ];
    } else if (category == 'pos') {
      details = [
        _buildDetailCard('Canteen Name', user['name'] ?? ''),
        _buildDetailCard('Canteen ID', user['canteen_id'] ?? ''),
        _buildDetailCard('Location', user['location'] ?? 'Not set'),
      ];
    } else if (category == 'cashier') {
      details = [
        _buildDetailCard('Name', user['name'] ?? ''),
        _buildDetailCard('Cashier ID', user['cashier_id'] ?? ''),
        _buildDetailCard('Username', user['username'] ?? ''),
      ];
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 251, 251),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Color.fromARGB(255, 134, 23, 23)),
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
                        fontWeight: FontWeight.bold),
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
              child: ListView(
                children: [
                  ...details,
                  if (category == 'parent')
                    TextButton.icon(
                        onPressed: () => _editUser(context),
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text('Link another student',
                            style: TextStyle(color: Colors.white))),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                          context, Icons.edit, 'Edit', _editUser),
                      _buildActionButton(
                          context, Icons.delete, 'Delete', _deleteUser),
                      if (category == 'student')
                        _buildActionButton(
                          context,
                          user['is_locked'] == 1 ||
                                  user['is_locked'] == '1' ||
                                  user['is_locked'] == true
                              ? Icons.lock_open
                              : Icons.lock,
                          user['is_locked'] == 1 ||
                                  user['is_locked'] == '1' ||
                                  user['is_locked'] == true
                              ? 'Unlock'
                              : 'Lock',
                          _toggleStudentLock,
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
              color: Colors.black26.withValues(alpha: 0.4),
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
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class UserEditPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String category;

  const UserEditPage({
    super.key,
    required this.user,
    required this.category,
  });

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  static const _red = Color(0xFFC51F26);
  late final TextEditingController _name;
  late final TextEditingController _linked;
  late final TextEditingController _location;
  late final TextEditingController _username;
  late final TextEditingController _canteenId;
  late final TextEditingController _idController;
  late final TextEditingController _balanceController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: (user['name'] ?? '').toString());
    _linked = TextEditingController(
      text: widget.category == 'student'
          ? (user['parent_id'] ?? '').toString()
          : (user['student_nums'] ?? user['student_num'] ?? '').toString(),
    );
    _location = TextEditingController(text: (user['location'] ?? '').toString());
    _username = TextEditingController(text: (user['username'] ?? '').toString());
    _canteenId = TextEditingController(text: (user['canteen_id'] ?? '').toString());
    _idController = TextEditingController(text: _idField);
    _balanceController = TextEditingController(
      text: '\u20B1${double.tryParse(user['balance']?.toString() ?? '')?.toStringAsFixed(2) ?? '0.00'}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _linked.dispose();
    _location.dispose();
    _username.dispose();
    _canteenId.dispose();
    _idController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String get _idField => switch (widget.category) {
        'student' => (widget.user['student_num'] ?? '').toString(),
        'parent' => (widget.user['parent_id'] ?? '').toString(),
        'pos' => (widget.user['canteen_id'] ?? '').toString(),
        _ => (widget.user['cashier_id'] ?? '').toString(),
      };

  String get _idLabel => switch (widget.category) {
        'student' => 'Student Number',
        'parent' => 'Parent ID',
        'pos' => 'Canteen ID',
        _ => 'Cashier ID',
      };

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save changes?'),
        content: Text('Save the updated details for ${_name.text.trim()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final body = <String, String>{
        'category': widget.category,
        'id': _idField,
        'Fname': _name.text.trim(),
        'location': _location.text.trim(),
        'username': widget.category == 'cashier' ? _username.text.trim() : '',
        'canteen_id': widget.category == 'cashier' ? _canteenId.text.trim() : '',
      };
      if (widget.category == 'student' || widget.category == 'parent') {
        body['linked_id'] = _linked.text.trim();
      }
      final response = await http.post(
        Uri.parse(ApiConfig.url('koyah_nabago.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: body,
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode != 200 || data['status'] != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? 'Could not save changes.').toString())),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Color(0xFF299B0A), size: 42),
          title: const Text('Changes saved'),
          content: const Text('The user details have been updated.'),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _red),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _editCard(String label, TextEditingController controller,
      {bool enabled = true, String? hint}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF9E1B21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        readOnly: !enabled,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          prefixIcon: Icon(
            enabled ? Icons.edit_outlined : Icons.badge_outlined,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _editCard('Name', _name),
      _editCard(_idLabel, _idController, enabled: false),
    ];
    if (widget.category == 'student') {
      fields
        ..add(_editCard('Linked Parent ID', _linked, hint: 'None'))
        ..add(_editCard('Balance', _balanceController, enabled: false));
    } else if (widget.category == 'parent') {
      fields.add(_editCard('Linked Student IDs', _linked, hint: 'None'));
    } else if (widget.category == 'pos') {
      fields.add(_editCard('Location', _location, hint: 'Not set'));
    } else {
      fields
        ..add(_editCard('Username', _username))
        ..add(_editCard('Canteen ID', _canteenId));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: _red),
                  ),
                  Image.asset('assets/redlogo.png', height: 38),
                  const SizedBox(width: 12),
                  const Text('Edit User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: ListView(children: fields),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: _red,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ),
        ),
      ),
    );
  }
}
