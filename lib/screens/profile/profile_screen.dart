import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart'; // Ensure path points correctly to LoginScreen
import 'edit_profile_screen.dart'; // Handles name and image conversions
import '../feedback/feedback_screen.dart';     // Direct sub-collection database logger
import '../about_us/about_us_screen.dart';     // Static descriptive developer layout
import '../privacy_policy/privacy_policy_screen.dart'; // Static legal placeholder layout

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Fetches persistent user profile data from local storage cache
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      if (userData != null) {
        user = jsonDecode(userData);
      }
    } catch (e) {
      debugPrint('PROFILE DATA CACHE FETCH ERROR: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  /// Triggers out-of-app administrative reset emails safely via Firebase
  Future<void> handlePasswordReset() async {
    final userEmail = user?['email']?.toString().trim();

    if (userEmail == null || userEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email not found. Cannot reset password.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a secure password reset link to $userEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent! Check your inbox/Spam too.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to trigger reset email: $e')),
      );
    }
  }

  /// Clears active login authentication sessions and disk fingerprints cleanly
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from Lucid Pages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
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

  /// Native launcher block mapping support email intents smoothly
  void handleContactUs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support: lucidpages.app@gmail.com'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget buildAvatar() {
    final imageUrl = user?['imageUrl'];

    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 55,
          backgroundImage: MemoryImage(base64Decode(imageUrl.split(',').last)),
        );
      } catch (e) {
        debugPrint('AVATAR DECODE ERROR: $e');
      }
    }

    return const CircleAvatar(
      radius: 55,
      backgroundColor: Color(0xFF007BFF),
      child: Icon(Icons.person, size: 55, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// 👤 User Core Header Card Terminal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 25, top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    buildAvatar(),
                    const SizedBox(height: 12),
                    Text(
                      user?['name'] ?? 'Lucid Reader',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?['email'] ?? 'No authentication email connected',
                      style: const TextStyle(color: Color(0xFF777777), fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🛠️ Operational Menu Group Terminal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'ACCOUNT & SUPPORT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit, color: Color(0xFF007BFF)),
                            title: const Text('Edit Profile'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () async {
                              // Navigates to editor and reloads profile on completion
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                              loadData();
                            },
                          ),
                          const Divider(height: 1, indent: 50),
                          ListTile(
                            leading: const Icon(Icons.lock_reset, color: Colors.orange),
                            title: const Text('Reset Password'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: handlePasswordReset,
                          ),
                          const Divider(height: 1, indent: 50),
                          ListTile(
                            leading: const Icon(Icons.info_outline, color: Colors.teal),
                            title: const Text('About Us'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 50),
                          ListTile(
                            leading: const Icon(Icons.gavel, color: Colors.blueGrey),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 50),
                          ListTile(
                            leading: const Icon(Icons.chat_bubble_outline, color: Colors.purple),
                            title: const Text('Feedback'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              /// 🚪 Destructive Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                      ),
                    ),
                    onPressed: logout,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}