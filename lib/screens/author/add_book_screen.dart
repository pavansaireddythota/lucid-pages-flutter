import 'dart:convert';
import 'dart:io'
    as io; // Prefixed dart:io so it doesn't conflict or break on web platforms

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

  // FIXED: Changed from io.File? to XFile? for Web compatibility
  XFile? coverImageFile;
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

      // FIXED: Used web-compatible async .length() method instead of native .lengthSync()
      final int fileSizeInBytes = await image.length();
      final double fileSizeInKB = fileSizeInBytes / 1024;
      if (fileSizeInKB > 800) {
        showError(
          'Image is too large (Max: 800KB). Please choose a smaller file.',
        );
        return;
      }

      // FIXED: Read bytes cross-platform via XFile directly
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      String extension = image.path.split('.').last.toLowerCase();
      if (extension == 'jpg') {
        extension = 'jpeg';
      }

      setState(() {
        coverImageFile = image; // Stored safely as XFile
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveBook() async {
    if (userId.isEmpty) {
      showError('User session not found. Please log in again.');
      return;
    }

    if (titleController.text.trim().isEmpty) {
      return showError('Enter Book Title');
    }
    if (authorController.text.trim().isEmpty) {
      return showError('Enter Author Name');
    }
    if (descriptionController.text.trim().isEmpty) {
      return showError('Enter Description');
    }
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

        // FIXED: Check if BOTH the description field and the Quill editor are empty
        final bool isQuillEmpty =
            episode.quillController.document.isEmpty() ||
            episode.quillController.document.length <= 1;

        if (currentEpDesc.isEmpty && isQuillEmpty) {
          showError('Episode ${i + 1} content or description summary required');
          throw Exception('Validation failed: Missing episode content');
        }

        if (seenTitles.contains(currentEpTitle.toLowerCase())) {
          showError(
            'Episode title "$currentEpTitle" is used multiple times. Please use unique titles.',
          );
          throw Exception(
            'Validation failed: Duplicate episode title detected',
          );
        }
        seenTitles.add(currentEpTitle.toLowerCase());

        // FIXED: Smart Content Generation Strategy
        // If they typed their main text inside the description field but left Quill empty,
        // we convert the description text to HTML paragraphs so your reader view doesn't break.
        String html = '';
        if (!isQuillEmpty) {
          final delta = episode.quillController.document.toDelta();
          final converter = QuillDeltaToHtmlConverter(
            List<Map<String, dynamic>>.from(delta.toJson()),
          );
          html = converter.convert();
        } else {
          // Convert plaintext formatting into basic HTML paragraphs
          html = currentEpDesc.split('\n').map((p) => '<p>$p</p>').join();
        }

        episodeList.add({
          'id': i + 1,
          'bookId': bookRef.id,
          'authorId': userId,
          'authorName': currentAuthorName,
          'title': currentEpTitle,
          'description': currentEpDesc.length > 100
              ? '${currentEpDesc.substring(0, 97)}...'
              : currentEpDesc, // Keeps the actual index summary clean
          'visibility': episode.visibility,
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

                // 2. Episode Content Field (Accepts unlimited long-form text entry)
                TextField(
                  controller: episode.descriptionController,
                  maxLines:
                      null, // FIXED: Setting to null allows it to auto-expand vertically with no size limits
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Episode Content / Description Text',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // 3. Episode-Specific Status Dropdown Selection UI
                DropdownButtonFormField<String>(
                  initialValue: episode.visibility,
                  decoration: const InputDecoration(
                    labelText: 'Episode Access Visibility',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'public',
                      child: Text('Public (Available to readers)'),
                    ),
                    DropdownMenuItem(
                      value: 'private',
                      child: Text('Private (Draft Mode)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      episode.visibility = value!;
                    });
                  },
                ),
                const SizedBox(height: 15),

                // Rich Text Section (Optional Backup Component)
                Container(
                  height: 200,
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
                          config: const QuillEditorConfig(scrollable: true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
              initialValue: visibility,
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
                    if (coverImageFile != null && coverImageBase64.isNotEmpty)
                      Image.memory(
                        base64Decode(coverImageBase64.split(',').last),
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

// Data holder pattern
class EpisodeModel {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String visibility = 'private';
  final quillController = QuillController.basic();
  bool expanded = true;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    quillController.dispose();
  }
}
