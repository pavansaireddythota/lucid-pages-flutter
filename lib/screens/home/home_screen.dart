import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../chapter/chapter_screen.dart'; // Ensure this matches your project file structure

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Helper widget to display base64 data strings or standard network image URLs
  Widget _buildCoverImage(String? coverData) {
    if (coverData == null || coverData.isEmpty) {
      return const Center(
        child: Icon(Icons.book, size: 60, color: Colors.grey),
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
              child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
            );
          },
        );
      }
    } catch (e) {
      return const Center(
        child: Icon(Icons.book, size: 60, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Public Stories'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen exclusively to stories set to public visibility level
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('visibility', isEqualTo: 'public')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong loading stories.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No public stories available.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final book = doc.data() as Map<String, dynamic>;
              
              // Ensure doc identifier is assigned to map
              book['id'] = doc.id;

              return GestureDetector(
                onTap: () {
                  final List episodes = book['episodes'] ?? [];
                  
                  if (episodes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This book does not have any chapters yet.')),
                    );
                    return;
                  }

                  // Direct routing explicitly to the transit ChapterScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterScreen(book: book),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 5,
                        color: Colors.black12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 0.7,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: _buildCoverImage(book['coverImageUrl']),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book['title'] ?? 'Untitled Story',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book['author'] ?? 'Unknown Author',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}