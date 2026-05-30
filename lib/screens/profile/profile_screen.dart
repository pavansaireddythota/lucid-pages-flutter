import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart'; // Make sure this path correctly points to your LoginScreen file

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  String? gender;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userData = prefs.getString('user');
      final genderData = prefs.getString('gender');

      if (userData != null) {
        user = jsonDecode(userData);
      }

      gender = genderData;
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // 1. Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // 2. Clear entire local disk storage footprint
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // 3. Clear stack context and route back to entry-point authentication
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  Widget buildAvatar() {
    final imageUrl = user?['imageUrl'];

    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(base64Decode(imageUrl.split(',').last)),
      );
    }

    return const CircleAvatar(radius: 60, child: Icon(Icons.person, size: 50));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    buildAvatar(),
                    const SizedBox(height: 10),
                    Text(
                      user?['name'] ?? 'Reader',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?['email'] ?? 'No Email',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Text('📚'),
                      title: Text('My Library'),
                    ),
                    ListTile(
                      leading: Text('🕒'),
                      title: Text('Reading History'),
                    ),
                    ListTile(
                      leading: Text('⚙️'),
                      title: Text('Settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: logout,
                    child: const Text(
                      '🚪 Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}