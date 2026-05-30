import 'dart:io';
import 'package:flutter/material.dart';

class ProfileImagePicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;

  const ProfileImagePicker({
    super.key,
    required this.imageFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage:
                imageFile != null
                    ? FileImage(imageFile!)
                    : null,
            child:
                imageFile == null
                    ? const Icon(
                        Icons.camera_alt,
                        size: 40,
                      )
                    : null,
          ),

          const SizedBox(height: 10),

          const Text(
            'Add Profile Photo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Recommended: JPG/PNG • 400×400 • Below 300 KB',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const Text(
            'Maximum Allowed: 500 KB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}