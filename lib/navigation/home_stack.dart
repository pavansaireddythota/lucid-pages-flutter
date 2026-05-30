import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/author/author_dashboard_screen.dart';
import '../screens/home/home_screen.dart';

class HomeStack extends StatefulWidget {
  const HomeStack({super.key});

  @override
  State<HomeStack> createState() => _HomeStackState();
}

class _HomeStackState extends State<HomeStack> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      debugPrint('====================');
      debugPrint('USER DATA: $userData');
      debugPrint('====================');

      if (userData != null) {
        user = jsonDecode(userData);
      }
    } catch (e) {
      debugPrint('Error loading user within HomeStack: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Safely extract, clean, and normalize the role string
    final role = user?['role']?.toString().trim().toLowerCase();
    
    debugPrint('EVALUATED ROLE (NORMALIZED): "$role"');

    if (role == 'author') {
      debugPrint('NAVIGATING TO AUTHOR DASHBOARD');
      return const AuthorDashboardScreen();
    }

    debugPrint('NAVIGATING TO HOME SCREEN');
    return const HomeScreen();
  }
}