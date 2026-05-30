import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;
  bool loading = false;

  String imageBase64 = '';
  File? imageFile;

  String passwordStrength = '';

  final allowedDomains = ['gmail.com', 'yahoo.com', 'outlook.com'];
  Future<void> selectImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 400,
      maxHeight: 400,
    );

    if (image == null) return;

    final file = File(image.path);

    final fileSize = await file.length();

    // 500 KB limit
    const maxSize = 500 * 1024;

    if (fileSize > maxSize) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image too large. Please select an image below 500 KB. Recommended size is under 300 KB.',
          ),
        ),
      );

      return;
    }

    final bytes = await file.readAsBytes();

    final base64String = base64Encode(bytes);

    setState(() {
      imageFile = file;
      imageBase64 = 'data:image/jpeg;base64,$base64String';
    });
  }

  bool validateEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!regex.hasMatch(email)) {
      return false;
    }

    final domain = email.split('@').last.toLowerCase();

    return allowedDomains.contains(domain);
  }

  void checkPasswordStrength(String password) {
    String strength = 'Weak';

    if (password.length >= 6 && RegExp(r'[A-Z]').hasMatch(password)) {
      strength = 'Medium';
    }

    if (password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*()]').hasMatch(password)) {
      strength = 'Strong';
    }

    setState(() {
      passwordStrength = strength;
    });
  }

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        imageBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select photo'),
        ),
      );
      return;
    }

    if (!validateEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use gmail, yahoo or outlook')),
      );
      return;
    }

    if (passwordStrength != 'Strong') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use a stronger password')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      final user = credential.user!;

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'name': nameController.text,
        'role': 'User',
        'imageUrl': imageBase64,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .set(userData);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user', jsonEncode(userData));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account Created')));

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration Failed')),
      );
    }

    setState(() {
      loading = false;
    });
  }

  Color strengthColor() {
    switch (passwordStrength) {
      case 'Strong':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              GestureDetector(
                onTap: selectImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: imageFile != null
                      ? FileImage(imageFile!)
                      : null,
                  child: imageFile == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Recommended: JPG/PNG • 400x400 • Below 300 KB\nMaximum allowed: 500 KB',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const Text('Start your reading journey'),

              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                onChanged: checkPasswordStrength,
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),

              if (passwordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Strength: $passwordStrength',
                    style: TextStyle(
                      color: strengthColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              const Text(
                'Use 8+ chars, uppercase, number & special character',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
