import 'dart:convert';
import 'package:flutter/material.dart';
import '../reader/reader_screen.dart'; // Ensure this points to your reader screen location

class ChapterScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  const ChapterScreen({super.key, required this.book});

  /// Helper widget to handle base64 image strings or network links smoothly
  Widget _buildCoverImage(String? coverData) {
    if (coverData == null || coverData.isEmpty) {
      return const Center(child: Icon(Icons.book, size: 50, color: Colors.grey));
    }
    try {
      if (coverData.startsWith('data:image/') && coverData.contains(';base64,')) {
        final base64String = coverData.split(';base64,').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } else {
        return Image.network(
          coverData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
        );
      }
    } catch (e) {
      return const Center(child: Icon(Icons.book, size: 50, color: Colors.grey));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List episodes = book['episodes'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(book['title'] ?? 'Story Index'),
      ),
      body: Column(
        children: [
          /// Header Details Block
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  height: 130,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildCoverImage(book['coverImageUrl']),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'Untitled Story',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${book['author'] ?? 'Unknown Author'}',
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${episodes.length} Chapters',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          /// Chapter Directory Listing
          Expanded(
            child: ListView.separated(
              itemCount: episodes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return ListTile(
                  leading: Text(
                    '${index + 1}.',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
                  ),
                  title: Text(
                    episode['title'] ?? 'Chapter ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderScreen(
                          book: book,
                          episodeIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}