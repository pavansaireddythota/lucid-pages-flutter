import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/auth/login_screen.dart';
import 'bottom_tab_screen.dart';

// Import supplemental configuration screens
import '../screens/about_us/about_us_screen.dart';
import '../screens/privacy_policy/privacy_policy_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/feedback/feedback_screen.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  String role = 'User';
  late Future<void> _loadRoleFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future execution to prevent rebuild loops on state mutations
    _loadRoleFuture = loadRole();
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final user = jsonDecode(userString);
      role = user['role'] ?? 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadRoleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Route unauthenticated traffic straight to Login Screen
            if (authSnapshot.data == null) {
              return const LoginScreen();
            }

            // User session verified -> Render core shell with localized named route mappings
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: BottomTabScreen(role: role),
              routes: {
                '/edit-profile': (context) => const EditProfileScreen(),
                '/feedback': (context) => const FeedbackScreen(),
                '/about-us': (context) => const AboutUsScreen(),
                '/privacy-policy': (context) => const PrivacyPolicyScreen(),
              },
            );
          },
        );
      },
    );
  }
}