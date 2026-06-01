import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Map<String, dynamic>? _userData;
  String? _base64ImageString;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Extracts currently cached session information
  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localUserJson = prefs.getString('user');
      
      if (localUserJson != null) {
        _userData = jsonDecode(localUserJson);
        _nameController.text = _userData?['name'] ?? '';
        _base64ImageString = _userData?['imageUrl'];
      }
    } catch (e) {
      debugPrint('Error accessing storage configurations: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Triggers device native image-picker interface, performs size filtering, and updates data structure
  Future<void> _pickAndProcessImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Built-in compression ratio reduction
      );

      if (pickedFile == null) return;

      // Validate platform file constraints (<500 KB limit rule engine)
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final double sizeInKb = imageBytes.lengthInBytes / 1024;

      if (sizeInKb > 500) {
        if (!mounted) return;
        _showErrorSnackBar('Image is too large (${sizeInKb.toStringAsFixed(1)}KB). Please select an image under 500KB.');
        return;
      }

      // Convert image streams into a single text Base64 data block string cleanly
      final String rawBase64 = base64Encode(imageBytes);
      
      setState(() {
        _base64ImageString = rawBase64;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to read or upload image: $e');
    }
  }

  /// Atomically commits profile updates across database layer and device memory block cache
  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final userInstance = FirebaseAuth.instance.currentUser;
    if (userInstance == null) {
      _showErrorSnackBar('User session context invalid. Please log in again.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String updatedName = _nameController.text.trim();
    final String targetUid = userInstance.uid;

    try {
      // 1. Prepare map payload
      final Map<String, dynamic> updatedProfilePayload = {
        'uid': targetUid,
        'email': _userData?['email'] ?? userInstance.email ?? '',
        'role': _userData?['role'] ?? 'reader',
        'name': updatedName,
        'imageUrl': _base64ImageString ?? '',
      };

      // 2. Perform remote updates directly against the target Firestore Document path
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(targetUid)
          .update({
            'name': updatedName,
            'imageUrl': _base64ImageString ?? '',
          });

      // 3. Write updates locally inside persistent device configuration registers
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedProfilePayload));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details updated successfully!')),
      );
      
      // Close editor screen to automatically trigger parental reload handlers
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Failed to update remote profile database data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_base64ImageString != null && _base64ImageString!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 65,
          backgroundImage: MemoryImage(base64Decode(_base64ImageString!.split(',').last)),
        );
      } catch (e) {
        debugPrint('Image serialization parse breakdown logic invoked: $e');
      }
    }
    return const CircleAvatar(
      radius: 65,
      backgroundColor: Color(0xFFE2E8F0),
      child: Icon(Icons.person, size: 65, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  /// Dynamic Avatar Stack & File Picker Interface Trigger
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF007BFF), width: 2),
                        ),
                        child: _buildImagePreview(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF007BFF),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            onPressed: _isSaving ? null : _pickAndProcessImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  const Text(
                    'Max file size requirement: 500 KB',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 35),

                  /// Profile Text Inputs
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isSaving,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF007BFF), width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid descriptive display name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  /// Submit Button Terminal
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                      onPressed: _isSaving ? null : _saveProfileChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Transformations',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}