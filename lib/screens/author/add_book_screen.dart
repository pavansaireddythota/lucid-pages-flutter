import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final descriptionController = TextEditingController();

  bool loading = false;
  String visibility = 'private'; // Root overall book level visibility
  File? coverImageFile;
  String coverImageBase64 = '';
  String userId = '';
  List<EpisodeModel> episodes = [];

  @override
  void initState() {
    super.initState();
    loadUser();
    addEpisode(); 
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    descriptionController.dispose();
    for (final ep in episodes) {
      ep.dispose();
    }
    super.dispose();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString == null) return;

    final user = jsonDecode(userString);
    setState(() {
      userId = user['uid'] ?? '';
      authorController.text = user['name'] ?? '';
    });
  }

  Future<void> pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 500,
        maxHeight: 700,
      );

      if (image == null) return;
      final file = File(image.path);

      final int fileSizeInBytes = file.lengthSync();
      final double fileSizeInKB = fileSizeInBytes / 1024;
      if (fileSizeInKB > 800) {
        showError('Image is too large (Max: 800KB). Please choose a smaller file.');
        return;
      }

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      String extension = image.path.split('.').last.toLowerCase();
      if (extension == 'jpg') {
        extension = 'jpeg';
      }

      setState(() {
        coverImageFile = file;
        coverImageBase64 = 'data:image/$extension;base64,$base64String';
      });
    } catch (e) {
      debugPrint('IMAGE PICKER ERROR: $e');
    }
  }

  void addEpisode() {
    setState(() {
      episodes.add(EpisodeModel());
    });
  }

  void removeEpisode(int index) {
    if (episodes.length == 1) {
      showError('At least one episode is required.');
      return;
    }

    setState(() {
      episodes.removeAt(index);
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveBook() async {
    if (userId.isEmpty) {
      showError('User session not found. Please log in again.');
      return;
    }

    if (titleController.text.trim().isEmpty) return showError('Enter Book Title');
    if (authorController.text.trim().isEmpty) return showError('Enter Author Name');
    if (descriptionController.text.trim().isEmpty) return showError('Enter Description');
    if (coverImageBase64.isEmpty) return showError('Select Cover Image');
    if (episodes.isEmpty) return showError('Add At Least One Episode');

    setState(() {
      loading = true;
    });

    try {
      final bookRef = FirebaseFirestore.instance.collection('books').doc();
      final List<Map<String, dynamic>> episodeList = [];
      final currentAuthorName = authorController.text.trim();
      
      final Set<String> seenTitles = {};

      for (int i = 0; i < episodes.length; i++) {
        final episode = episodes[i];
        final currentEpTitle = episode.titleController.text.trim();
        final currentEpDesc = episode.descriptionController.text.trim();

        if (currentEpTitle.isEmpty) {
          showError('Episode ${i + 1} title required');
          throw Exception('Validation failed: Missing episode title');
        }

        if (currentEpDesc.isEmpty) {
          showError('Episode ${i + 1} description required');
          throw Exception('Validation failed: Missing episode description');
        }

        if (seenTitles.contains(currentEpTitle.toLowerCase())) {
          showError('Episode title "$currentEpTitle" is used multiple times. Please use unique titles.');
          throw Exception('Validation failed: Duplicate episode title detected');
        }
        seenTitles.add(currentEpTitle.toLowerCase());

        final plainText = episode.quillController.document.toPlainText().trim();
        if (plainText.isEmpty) {
          showError('Episode ${i + 1} content cannot be empty');
          throw Exception('Validation failed: Missing episode content');
        }

        final delta = episode.quillController.document.toDelta();
        final converter = QuillDeltaToHtmlConverter(
          List<Map<String, dynamic>>.from(delta.toJson()),
        );
        final html = converter.convert();

        episodeList.add({
          'id': i + 1,
          'bookId': bookRef.id,
          'authorId': userId,
          'authorName': currentAuthorName,
          'title': currentEpTitle,
          'description': currentEpDesc,
          'visibility': episode.visibility, // New Episode-level security data
          'content': html,
        });
      }

      final bookData = {
        'id': bookRef.id,
        'title': titleController.text.trim(),
        'author': currentAuthorName,
        'description': descriptionController.text.trim(),
        'coverImageUrl': coverImageBase64,
        'visibility': visibility,
        'createdAt': FieldValue.serverTimestamp(), 
        'authorId': userId,
        'episodes': episodeList,
        'episodeCount': episodeList.length, 
      };

      await bookRef.set(bookData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book Created Successfully')),
      );
      Navigator.pop(context);

    } catch (e) {
      debugPrint('SAVE BOOK ERROR: $e');
      if (!e.toString().contains('Validation failed')) {
        showError('Failed To Save Book');
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget buildEpisodeCard(int index) {
    final episode = episodes[index];

    return Card(
      key: ObjectKey(episode),
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          episode.titleController.text.isEmpty
              ? 'Episode ${index + 1}'
              : episode.titleController.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 1. Episode Title Field
                TextField(
                  controller: episode.titleController,
                  decoration: const InputDecoration(
                    labelText: 'Episode Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 15),

                // 2. NEW: Episode Description Field
                TextField(
                  controller: episode.descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Episode Description Summary',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // 3. NEW: Episode-Specific Status Dropdown Selection UI
                DropdownButtonFormField<String>(
                  value: episode.visibility,
                  decoration: const InputDecoration(
                    labelText: 'Episode Access Visibility',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public (Available to readers)')),
                    DropdownMenuItem(value: 'private', child: Text('Private (Draft Mode)')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      episode.visibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 15),
                
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      QuillSimpleToolbar(
                        controller: episode.quillController,
                        config: const QuillSimpleToolbarConfig(),
                      ),
                      Expanded(
                        child: QuillEditor.basic(
                          controller: episode.quillController,
                          config: const QuillEditorConfig(
                            scrollable: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => removeEpisode(index),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text(
                      'Delete Episode',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(title: const Text('Add New Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Author Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Book Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: visibility,
              decoration: const InputDecoration(
                labelText: 'Global Book Visibility',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
              ],
              onChanged: (value) {
                setState(() {
                  visibility = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickCoverImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    if (coverImageFile != null)
                      Image.file(
                        coverImageFile!,
                        height: 220,
                        fit: BoxFit.contain,
                      )
                    else
                      const Icon(Icons.image, size: 70),
                    const SizedBox(height: 10),
                    const Text('Select Cover Image'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Episodes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              episodes.length,
              (index) => buildEpisodeCard(index),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addEpisode,
                icon: const Icon(Icons.add),
                label: const Text('Add Episode'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : saveBook,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Book'),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// Updated data holder pattern
class EpisodeModel {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController(); // Added description storage tracking map
  String visibility = 'private';                        // Added tracking default initial dropdown state mapping
  final quillController = QuillController.basic();
  bool expanded = true;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose(); // Housekeeping cleanup to prevent memory leaks
    quillController.dispose();
  }
}