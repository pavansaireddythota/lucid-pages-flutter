import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_book_screen.dart';
import 'edit_book_screen.dart';

class AuthorDashboardScreen extends StatefulWidget {
  const AuthorDashboardScreen({super.key});

  @override
  State<AuthorDashboardScreen> createState() => _AuthorDashboardScreenState();
}

class _AuthorDashboardScreenState extends State<AuthorDashboardScreen> {
  List<Map<String, dynamic>> books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null || currentUserId.isEmpty) {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('authorId', isEqualTo: currentUserId)
          .get();

      final list = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          books = List<Map<String, dynamic>>.from(list);
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('FETCH BOOKS ERROR: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> deleteBook(String bookId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      await fetchBooks();
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
    }
  }

  String _formatCreationDate(dynamic rawDate) {
    if (rawDate == null) return '';
    try {
      if (rawDate is Timestamp) {
        return rawDate.toDate().toString().split(' ').first;
      } else if (rawDate is String) {
        return DateTime.parse(rawDate).toString().split(' ').first;
      }
    } catch (e) {
      debugPrint('Date parsing exception: $e');
    }
    return '';
  }

  Widget buildBookCard(Map<String, dynamic> book) {
    final List episodesList = book['episodes'] ?? [];
    final int episodeCount = book['episodeCount'] ?? episodesList.length;
    final String visibility = (book['visibility'] ?? 'private').toString().toLowerCase();
    final String formattedDate = _formatCreationDate(book['createdAt']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((book['coverImageUrl'] ?? '').toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Builder(
                builder: (context) {
                  try {
                    final base64String = (book['coverImageUrl'] as String).split(',').last;
                    return Image.memory(
                      base64Decode(base64String),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildFallbackCoverImage(),
                    );
                  } catch (e) {
                    return _buildFallbackCoverImage();
                  }
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Untitled Book',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${book['author'] ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                
                if (formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Created: $formattedDate',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🎬 $episodeCount ${episodeCount == 1 ? "Episode" : "Episodes"}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: visibility == 'public'
                            ? Colors.green.withValues(alpha: .1)
                            : Colors.orange.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BOOK: ${visibility.toUpperCase()}',
                        style: TextStyle(
                          color: visibility == 'public' ? Colors.green[800] : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                if (episodesList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(
                    'Episodes Overview:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ...episodesList.take(3).map((ep) {
                    final String epVisibility = (ep['visibility'] ?? 'private').toString().toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            epVisibility == 'public' ? Icons.visibility : Icons.visibility_off,
                            size: 14,
                            color: epVisibility == 'public' ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ep['title'] ?? 'Untitled Episode',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((ep['description'] ?? '').toString().isNotEmpty)
                                  Text(
                                    ep['description'],
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (episodesList.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '+ ${episodesList.length - 3} more episodes...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Edit Book & Episodes'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditBookScreen(book: book),
                            ),
                          ).then((_) async => await fetchBooks());
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => deleteBook(book['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCoverImage() {
    return Container(
      height: 160,
      color: Colors.grey[200],
      width: double.infinity,
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('📚 Author Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchBooks,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchBooks,
              child: books.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Center(
                          child: Text(
                            'No books written yet. Create one below!',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return buildBookCard(books[index]);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Book', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookScreen()),
          ).then((_) async => await fetchBooks());
        },
      ),
    );
  }
}