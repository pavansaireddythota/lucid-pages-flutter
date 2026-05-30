import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/auth/login_screen.dart';
import 'bottom_tab_screen.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() =>
      _AppNavigatorState();
}

class _AppNavigatorState
    extends State<AppNavigator> {
  String role = 'User';

  Future<void> loadRole() async {
    final prefs =
        await SharedPreferences.getInstance();

    final userString =
        prefs.getString('user');

    if (userString != null) {
      final user =
          jsonDecode(userString);

      role = user['role'] ?? 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadRole(),
      builder: (context, snapshot) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance
              .authStateChanges(),
          builder: (
            context,
            authSnapshot,
          ) {
            if (authSnapshot
                    .connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              );
            }

            if (authSnapshot.data ==
                null) {
              return const LoginScreen();
            }

            return BottomTabScreen(
              role: role,
            );
          },
        );
      },
    );
  }
}