import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../book_details/book_details_screen.dart'; // Target routing file when a book card is tapped

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  /// Helper widget to securely parse and build base64 data strings or network links
  Widget _buildCoverImage(String? coverData) {
    if (coverData == null || coverData.isEmpty) {
      return const Center(
        child: Icon(Icons.book, size: 50, color: Colors.grey),
      );
    }

    try {
      if (coverData.startsWith('data:image/') && coverData.contains(';base64,')) {
        final base64String = coverData.split(';base64,').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
        );
      } else {
        return Image.network(
          coverData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            );
          },
        );
      }
    } catch (e) {
      return const Center(
        child: Icon(Icons.book, size: 50, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Handle anonymous or logged-out platform states safely
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('📚 My Shelf')),
        body: const Center(
          child: Text(
            'Please log in to view your personal library shelf.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 My Shelf'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listens in real-time to this specific user's saved books collection
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('library')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong loading your shelf.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Condition: If there are no books saved, show the empty message
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_library, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No books available on your shelf.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Condition: If there are books, render them in a clean list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final book = doc.data() as Map<String, dynamic>;
              
              // Maintain document ID fallback consistency
              book['id'] = doc.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: SizedBox(
                    width: 50,
                    height: 75,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: _buildCoverImage(book['coverImageUrl']),
                    ),
                  ),
                  title: Text(
                    book['title'] ?? 'Untitled Story',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      book['author'] ?? 'Unknown Author',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Smoothly navigates to the detailed specifications book layout
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}