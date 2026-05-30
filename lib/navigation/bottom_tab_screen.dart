import 'package:flutter/material.dart';

import '../screens/library/library_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'home_stack.dart';

class BottomTabScreen extends StatefulWidget {
  final String role;

  const BottomTabScreen({
    super.key,
    required this.role,
  });

  @override
  State<BottomTabScreen> createState() =>
      _BottomTabScreenState();
}

class _BottomTabScreenState
    extends State<BottomTabScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAuthor =
        widget.role.toLowerCase() ==
        'author';

    final screens = isAuthor
        ? [
            const HomeStack(),
            const ProfileScreen(),
          ]
        : [
            const HomeStack(),
            const LibraryScreen(),
            const ProfileScreen(),
          ];

    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: isAuthor
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.dashboard,
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person,
                  ),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon:
                      Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon:
                      Icon(Icons.menu_book),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon:
                      Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}