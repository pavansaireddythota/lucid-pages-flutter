import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/library_service.dart';
import '../chapter/chapter_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Widget _buildCoverImage(String? coverData) {
    if (coverData == null || coverData.isEmpty) {
      return const Center(child: Icon(Icons.book, size: 50, color: Colors.grey));
    }

    try {
      if (coverData.startsWith('data:image/')) {
        final base64String = coverData.split(';base64,').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      }
      return Image.network(coverData, fit: BoxFit.cover);
    } catch (_) {
      return const Center(child: Icon(Icons.book, size: 50, color: Colors.grey));
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

          // Wrap grid system in a centered, max-width boundary for web displays
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                // Automatically switches layout configurations depending on the desktop window real estate
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // Keeps your cards tightly and elegantly proportioned
                  childAspectRatio: 0.60,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: _buildCoverImage(book['coverImageUrl']),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book['author'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}