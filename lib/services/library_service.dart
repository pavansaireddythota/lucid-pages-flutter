import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get uid => _auth.currentUser!.uid;

  static Future<void> saveBook(Map<String, dynamic> book) async {
    await _firestore
        .collection('Users')
        .doc(uid)
        .collection('library')
        .doc(book['id'])
        .set({
          'bookId': book['id'],
          'title': book['title'],
          'author': book['author'],
          'coverImageUrl': book['coverImageUrl'],
          'episodes': book['episodes'] ?? [],
          'savedAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> removeBook(String bookId) async {
    await _firestore
        .collection('Users')
        .doc(uid)
        .collection('library')
        .doc(bookId)
        .delete();
  }

  static Stream<QuerySnapshot> libraryStream() {
    return _firestore
        .collection('Users')
        .doc(uid)
        .collection('library')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  static Future<bool> isBookSaved(String bookId) async {
    final doc = await _firestore
        .collection('Users')
        .doc(uid)
        .collection('library')
        .doc(bookId)
        .get();

    return doc.exists;
  }
}
