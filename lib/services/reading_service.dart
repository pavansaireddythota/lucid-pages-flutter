import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReadingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get uid => _auth.currentUser!.uid;

  static Future<void> saveProgress({
    required Map<String, dynamic> book,
    required int currentChapter,
    required int totalChapters,
  }) async {
    final progress = ((currentChapter + 1) / totalChapters * 100);

    await _firestore
        .collection('Users')
        .doc(uid)
        .collection('reading_history')
        .doc(book['id'])
        .set({
          'bookId': book['id'],
          'title': book['title'],
          'author': book['author'],
          'coverImageUrl': book['coverImageUrl'],

          'book': book,

          'lastChapter': currentChapter,
          'totalChapters': totalChapters,

          'progress': progress,

          'lastRead': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _updateStats();
  }

  static Future<void> _updateStats() async {
    await _firestore
        .collection('Users')
        .doc(uid)
        .collection('stats')
        .doc('reading')
        .set({
          'chaptersRead': FieldValue.increment(1),
        }, SetOptions(merge: true));
  }
}
