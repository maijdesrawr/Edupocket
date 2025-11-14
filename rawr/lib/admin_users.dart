import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_details.dart';
import 'koyah_nadagdag.dart';
import 'admin_home.dart';
import 'admin_report.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({Key? key}) : super(key: key);

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // Users tab selected

  Map<String, List<dynamic>> users = {'student': [], 'parent': [], 'pos': []};
  Map<String, bool> loading = {'student': false, 'parent': false, 'pos': false};

  static const Color vividRed = Color(0xFFcf302e);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    fetchUsers('student');

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      switch (_tabController.index) {
        case 0:
          fetchUsers('student');
          break;
        case 1:
          fetchUsers('parent');
          break;
        case 2:
          fetchUsers('pos');
          break;
      }
    });
  }

  Future<void> fetchUsers(String category) async {
    if (loading[category] == true) return;

    setState(() => loading[category] = true);

    try {
      final response = await http.get(
        Uri.parse('http://10.104.13.218:8000/get_users.php?category=$category'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => users[category] = data['data']);
        } else {
          print("Error: ${data['message']}");
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch error: $e");
    } finally {
      setState(() => loading[category] = false);
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminHome(name: "Admin", id: "0"),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AdminReportsPage(adminName: "Admin", adminId: "0"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Student'),
            Tab(text: 'Parent'),
            Tab(text: 'POS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildUserList('student'),
          buildUserList('parent'),
          buildUserList('pos'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          final categories = ['student', 'parent', 'pos'];
          final currentCategory = categories[_tabController.index];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddUser(category: currentCategory),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTap,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: vividRed,
            unselectedItemColor: Colors.black54,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserList(String category) {
    if (loading[category] == true) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users[category]!.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: users[category]!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final user = users[category]![i];

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.red[700],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                user['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(category[0].toUpperCase() + category.substring(1)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetails(user: user, category: category),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
