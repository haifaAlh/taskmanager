import 'package:flutter/material.dart';
import 'package:taskmanager/pages/home_page.dart';
import 'package:taskmanager/pages/profile.dart';
import 'package:taskmanager/pages/workspaces.dart' show WorkspacesPage;
import 'package:taskmanager/pages/notifications_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showNotifications = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5B32E4);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Stack(
            fit: StackFit.expand,
            children: [
              HomePage(
                onOpenNotifications: () {
                  setState(() {
                    _showNotifications = true;
                  });
                },
              ),
              if (_showNotifications) const NotificationsPage(),
            ],
          ),
          const WorkspacesPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _showNotifications = false;
          });
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Workspaces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
