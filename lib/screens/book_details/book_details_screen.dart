import 'dart:convert';
import 'package:flutter/material.dart';
import '../chapter/chapter_screen.dart'; // Ensure this matches your project file path

class BookDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  /// Helper widget to seamlessly render Base64 strings or standard network links
  Widget _buildCoverImage(String? coverData) {
    if (coverData == null || coverData.isEmpty) {
      return const Center(
        child: Icon(Icons.book, size: 80, color: Colors.grey),
      );
    }

    try {
      if (coverData.startsWith('data:image/') && coverData.contains(';base64,')) {
        final base64String = coverData.split(';base64,').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
        );
      } else {
        return Image.network(
          coverData,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
            );
          },
        );
      }
    } catch (e) {
      return const Center(
        child: Icon(Icons.book, size: 80, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📚 Book Cover
            Container(
              color: Colors.white,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 0.7,
                child: _buildCoverImage(book['coverImageUrl']),
              ),
            ),

            /// 📄 Content Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Untitled Story',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'by ${book['author'] ?? 'Unknown Author'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF777777),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    book['description'] ?? 'No description available for this book.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF444444),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Interactive Access Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () {
                        // Directly routes to the dynamic interactive Chapter list screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChapterScreen(book: book),
                          ),
                        );
                      },
                      child: const Text(
                        'Start Reading',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}