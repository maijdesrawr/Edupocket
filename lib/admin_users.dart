import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'admin_home.dart';
import 'admin_profile.dart';
import 'admin_report.dart';
import 'app_session_service.dart';
import 'api_config.dart';
import 'koyah_nadagdag.dart';
import 'user_details.dart';

class AdminUsers extends StatefulWidget {
  final String adminName;
  final String adminId;

  const AdminUsers({
    super.key,
    required this.adminName,
    required this.adminId,
  });

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  static const Color _primaryRed = Color(0xFFC62828);
  static const Color _deepRed = Color(0xFFB71C1C);
  static const Color _softTab = Color(0xFFF4C7BE);
  static const Color _searchHint = Color(0xFF9B9B9B);

  static const List<String> _categories = [
    'student',
    'parent',
    'pos',
    'cashier',
  ];

  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 1;
  String _activeCategory = 'student';
  String? _selectedAction;

  final Map<String, List<dynamic>> _users = {
    'student': [],
    'parent': [],
    'pos': [],
    'cashier': [],
  };

  final Map<String, bool> _loading = {
    'student': false,
    'parent': false,
    'pos': false,
    'cashier': false,
  };

  final Map<String, String> _searchQuery = {
    'student': '',
    'parent': '',
    'pos': '',
    'cashier': '',
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery[_activeCategory] ?? '';
    fetchUsers(_activeCategory);
  }

  Future<void> fetchUsers(String category, {bool force = false}) async {
    if (!force && _loading[category] == true) return;
    setState(() => _loading[category] = true);

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.url('get_users.php?category=$category')),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && mounted) {
          final users = List<dynamic>.from(data['data'] ?? const []);
          setState(() {
            _users[category] = _sortUsers(category, users);
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading[category] = false);
    }
  }

  void _switchCategory(String category) {
    if (category == _activeCategory) return;

    setState(() {
      _activeCategory = category;
      _selectedAction = null;
    });
    _syncSearchField();
    fetchUsers(category);
  }

  void _syncSearchField() {
    final text = _searchQuery[_activeCategory] ?? '';
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery[_activeCategory] = value);
  }

  Future<void> _openAddUser() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddUser(category: _activeCategory),
      ),
    );

    if (changed == true) {
      setState(() => _searchQuery[_activeCategory] = '');
      _syncSearchField();
      await fetchUsers(_activeCategory, force: true);
    }
  }

  void _showStudentAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text(
                  "Create Family Account",
                ),
                subtitle: const Text(
                  "Create parent + first student",
                ),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddUser(
                        category: 'student',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text(
                  "Add Child",
                ),
                subtitle: const Text(
                  "Link child to existing parent",
                ),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddUser(
                        category: 'child',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openUserDetails(Map<String, dynamic> user) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetails(user: user, category: _activeCategory),
      ),
    );

    if (changed == true) {
      await fetchUsers(_activeCategory, force: true);
    }
  }

  Object? _userId(Map<String, dynamic> user) {
    switch (_activeCategory) {
      case 'student':
        return user['student_num'];
      case 'parent':
        return user['parent_id'];
      case 'pos':
        return user['canteen_id'];
      case 'cashier':
        return user['cashier_id'];
      default:
        return null;
    }
  }

  Future<void> _handleUserTap(Map<String, dynamic> user) async {
    switch (_selectedAction) {
      case 'edit':
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => UserEditPage(user: user, category: _activeCategory),
          ),
        );
        if (changed == true) await fetchUsers(_activeCategory, force: true);
        break;
      case 'delete':
        await _confirmDeleteUser(user);
        break;
      case 'lock':
        await _confirmToggleLock(user);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose Edit, Delete, or Lock first.')),
        );
    }
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
          'Delete ${_displayName(user)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _deepRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.url('account_delete.php')),
      headers: AppSessionService.instance.authorizationHeaders,
      body: {'category': _activeCategory, 'id': _userId(user)?.toString() ?? ''},
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _users[_activeCategory]?.remove(user);
          _selectedAction = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? 'User deleted.').toString())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? 'Could not delete user.').toString())),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this user. Try again.')),
      );
    }
  }

  Future<void> _confirmToggleLock(Map<String, dynamic> user) async {
    final locked = ['1', 'true'].contains(user['is_locked']?.toString().toLowerCase());
    final action = locked ? 'unlock' : 'lock';
    final accountType = _categoryLabel(_activeCategory);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${locked ? 'Unlock' : 'Lock'} $accountType?'),
        content: Text(locked
            ? 'Allow ${_displayName(user)} to use this account again?'
            : 'Lock this account? ${_displayName(user)} will not be able to access it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _deepRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(locked ? 'Unlock' : 'Lock'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final isStudent = _activeCategory == 'student';
      final response = await http.post(
        Uri.parse(ApiConfig.url(
            isStudent ? 'student_manual_lock.php' : 'admin_account_lock.php')),
        headers: AppSessionService.instance.authorizationHeaders,
        body: isStudent
            ? {'student_num': _userId(user)?.toString() ?? '', 'action': action}
            : {
                'category': _activeCategory,
                'id': _userId(user)?.toString() ?? '',
                'account_source': (user['account_source'] ?? '').toString(),
                'action': action,
              },
      );
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 && data['status'] == 'success') {
        await fetchUsers(_activeCategory, force: true);
        setState(() => _selectedAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? 'Account status updated.').toString())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((data['message'] ?? 'Could not update account status.').toString())),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this account. Try again.')),
      );
    }
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminHome(name: widget.adminName, id: widget.adminId),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminReportsPage(
            adminName: widget.adminName,
            adminId: widget.adminId,
          ),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminProfilePage(
            adminName: widget.adminName,
            adminId: widget.adminId,
          ),
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
            const SizedBox(height: 22),
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
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'User Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 12),
                      _buildCategoryTabs(),
                      const SizedBox(height: 12),
                      _buildSearchField(),
                      const SizedBox(height: 22),
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _buildCurrentCategoryList(),
                            ),
                            if (_activeCategory != 'parent')
                              Positioned(
                                right: 12,
                                bottom: 28,
                                child: _buildAddButton(),
                              ),
                          ],
                        ),
                      ),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        _actionButton('edit', Icons.edit_outlined, 'Edit'),
        const SizedBox(width: 8),
        _actionButton('delete', Icons.delete_outline, 'Delete'),
        const SizedBox(width: 8),
        _actionButton('lock', Icons.lock_outline, 'Lock'),
      ],
    );
  }

  Widget _actionButton(String action, IconData icon, String label,
      {bool enabled = true}) {
    final selected = _selectedAction == action;
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: selected ? _deepRed : Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: !enabled
                ? null
                : () => setState(() => _selectedAction = selected ? null : action),
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: selected ? Colors.white : _primaryRed),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                        color: selected ? Colors.white : _primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.black87, size: 22),
          hintText: 'Search By Name...',
          hintStyle: TextStyle(
            color: _searchHint,
            fontSize: 14,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _activeCategory == category;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _switchCategory(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? _deepRed : _softTab,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categoryLabel(category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _primaryRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCurrentCategoryList() {
    if (_loading[_activeCategory] == true) {
      return RefreshIndicator(
        color: _primaryRed,
        onRefresh: () => fetchUsers(_activeCategory, force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ],
        ),
      );
    }

    final filteredUsers = _filteredUsers(_activeCategory);
    if (filteredUsers.isEmpty) {
      return RefreshIndicator(
        color: _primaryRed,
        onRefresh: () => fetchUsers(_activeCategory, force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 92),
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: _buildEmptyState(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryRed,
      onRefresh: () => fetchUsers(_activeCategory, force: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 92),
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final user = filteredUsers[index] as Map<String, dynamic>;
          return _buildUserCard(user, _activeCategory);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'No matching users',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String category) {
    final isLocked =
        (int.tryParse(user['is_locked']?.toString() ?? '0') ?? 0) == 1;

    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _handleUserTap(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              _buildUserAvatar(user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked
                          ? '${_categoryLabel(category).toUpperCase()} LOCKED'
                          : _categoryLabel(category).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isLocked && category == 'student')
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.black,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> user) {
    final photoUrl = (user['photo_url'] ?? '').toString().trim();

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black,
      foregroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: const Icon(Icons.person, color: Colors.white, size: 28),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: _deepRed,
      elevation: 10,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (_activeCategory == 'student') {
            _showStudentAddOptions();
          } else {
            _openAddUser();
          }
        },
        child: const SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 28,
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

  List<dynamic> _filteredUsers(String category) {
    final query = (_searchQuery[category] ?? '').trim().toLowerCase();
    final source = _users[category] ?? const [];

    if (query.isEmpty) return source;

    return source.where((rawUser) {
      final user = rawUser as Map<String, dynamic>;
      final name = _displayName(user).toLowerCase();
      return name.contains(query);
    }).toList();
  }

  String _displayName(Map<String, dynamic> user) {
    final name = (user['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    return (user['username'] ?? 'User Name Here').toString();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'student':
        return 'Student';
      case 'parent':
        return 'Parent';
      case 'pos':
        return 'Canteen';
      case 'cashier':
        return 'Cashier';
      default:
        return category;
    }
  }

  List<dynamic> _sortUsers(String category, List<dynamic> users) {
    final sorted = List<dynamic>.from(users);

    String sortKey(Map<String, dynamic> user) {
      switch (category) {
        case 'student':
          return (user['student_num'] ?? '').toString();
        case 'parent':
          return (user['parent_id'] ?? '').toString();
        case 'pos':
          return (user['canteen_id'] ?? '').toString();
        case 'cashier':
          return (user['cashier_id'] ?? '').toString();
        default:
          return (user['name'] ?? '').toString();
      }
    }

    sorted.sort((a, b) {
      final left = sortKey(a as Map<String, dynamic>);
      final right = sortKey(b as Map<String, dynamic>);
      return right.compareTo(left);
    });

    return sorted;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
