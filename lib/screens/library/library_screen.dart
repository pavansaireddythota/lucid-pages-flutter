import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/library_service.dart';
import '../chapter/chapter_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Widget _buildCoverImage(String? coverData) {
    if (coverData == null || coverData.isEmpty) {
      return const Center(child: Icon(Icons.book));
    }

    try {
      if (coverData.startsWith('data:image/')) {
        final base64String = coverData.split(';base64,').last;

        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      }

      return Image.network(coverData, fit: BoxFit.cover);
    } catch (_) {
      return const Center(child: Icon(Icons.book));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Library")),
      body: StreamBuilder<QuerySnapshot>(
        stream: LibraryService.libraryStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!.docs;

          if (books.isEmpty) {
            return const Center(child: Text("No books saved yet"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .60,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final book = books[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterScreen(book: book),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  child: Column(
                    children: [
                      Expanded(child: _buildCoverImage(book['coverImageUrl'])),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Text(
                              book['title'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              book['author'] ?? '',
                              style: const TextStyle(color: Colors.grey),
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
