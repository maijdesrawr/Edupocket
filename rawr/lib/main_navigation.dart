import 'package:flutter/material.dart';
import 'parent.dart';
import 'topup.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  static const Color vividRed = Color(0xFFcf302e);

  void switchPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> pages = [
    ParentDashboard(name: "Sample Name", id: "1"),
    const TopUpContent(),
    const Center(child: Text('History Page Coming Soon')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: switchPage,
          selectedItemColor: vividRed,
          unselectedItemColor: Colors.black45,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Top-Up',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
