import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:image_picker/image_picker.dart';

class EditBookScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const EditBookScreen({
    super.key,
    required this.book,
  });

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController titleController;
  late TextEditingController authorNameController;
  late TextEditingController descriptionController;
  
  String? _coverBase64;
  String _visibility = 'public';
  bool isSaving = false;

  List<Map<String, dynamic>> localEpisodes = [];
  final List<quill.QuillController> _quillControllers = [];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.book['title'] ?? '');
    authorNameController = TextEditingController(text: widget.book['author'] ?? '');
    descriptionController = TextEditingController(text: widget.book['description'] ?? '');
    _visibility = widget.book['visibility'] ?? 'public';
    _coverBase64 = widget.book['coverImageUrl'];

    _initializeEpisodes();
  }

  /// Translates stored HTML strings into live Delta streams with defensive parsing error blocks
  void _initializeEpisodes() {
    if (widget.book['episodes'] != null) {
      final List rawEpisodes = widget.book['episodes'];
      for (var ep in rawEpisodes) {
        final episodeMap = Map<String, dynamic>.from(ep);
        
        // Ensure visibility safely defaults to a valid fallback state if absent
        if (episodeMap['visibility'] == null) {
          episodeMap['visibility'] = 'private';
        }
        if (episodeMap['description'] == null) {
          episodeMap['description'] = '';
        }

        localEpisodes.add(episodeMap);

        final htmlContent = episodeMap['content'] ?? '';
        quill.QuillController controller;
        
        if (htmlContent.toString().isNotEmpty) {
          try {
            final delta = HtmlToDelta().convert(htmlContent);
            controller = quill.QuillController(
              document: quill.Document.fromDelta(delta),
              selection: const TextSelection.collapsed(offset: 0),
            );
          } catch (e) {
            debugPrint('HTML PARSING EXCEPTION ENCOUNTERED: $e. Falling back to clean editor.');
            controller = quill.QuillController(
              document: quill.Document(),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        } else {
          controller = quill.QuillController(
            document: quill.Document(),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
        _quillControllers.add(controller);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorNameController.dispose();
    descriptionController.dispose();
    for (var controller in _quillControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Appends a new episodic block with a consistent map schema format
  void _addNewEpisode() {
    setState(() {
      localEpisodes.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'bookId': widget.book['id'],
        'authorId': widget.book['authorId'],
        'authorName': authorNameController.text.trim(),
        'title': '',
        'description': '', // Added tracking default parameter
        'visibility': 'private', // Match private default design state rules
        'content': '',
      });
      _quillControllers.add(quill.QuillController(
        document: quill.Document(),
        selection: const TextSelection.collapsed(offset: 0),
      ));
    });
  }

  /// Removes an episode canvas completely from local state, protecting against empty volume deletions
  void _deleteEpisode(int index) {
    if (localEpisodes.length <= 1) {
      _showSnackBar('At least one episode is required inside your book manuscript.');
      return;
    }

    setState(() {
      localEpisodes.removeAt(index);
      _quillControllers[index].dispose();
      _quillControllers.removeAt(index);
    });
  }

  /// Resolves exact MIME types and validates assets against a 500KB cap
  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      if (bytes.length > 500 * 1024) {
        _showSnackBar('Image asset allocation limit exceeded. Must be below 500KB.');
        return;
      }

      String extension = image.path.split('.').last.toLowerCase();
      if (extension == 'jpg') {
        extension = 'jpeg';
      }

      setState(() {
        _coverBase64 = 'data:image/$extension;base64,${base64Encode(bytes)}';
      });
    }
  }

  /// Comprehensively processes, compiles, and synchronizes document alterations with Firestore
  Future<void> saveCompleteBookChanges() async {
    final trimmedTitle = titleController.text.trim();
    final trimmedAuthor = authorNameController.text.trim();
    final trimmedDesc = descriptionController.text.trim();

    if (trimmedTitle.isEmpty) {
      _showSnackBar('Book title cannot be empty.');
      return;
    }
    if (trimmedAuthor.isEmpty) {
      _showSnackBar('Author display name is required.');
      return;
    }
    if (trimmedDesc.isEmpty) {
      _showSnackBar('Book description abstract synopsis is required.');
      return;
    }

    final Set<String> uniqueTitles = {};
    for (int i = 0; i < localEpisodes.length; i++) {
      final epTitle = localEpisodes[i]['title']?.toString().trim() ?? '';
      final epDesc = localEpisodes[i]['description']?.toString().trim() ?? '';

      if (epTitle.isEmpty) {
        _showSnackBar('Episode ${i + 1} requires a valid title.');
        return;
      }
      
      if (epDesc.isEmpty) {
        _showSnackBar('Episode ${i + 1} requires a description summary.');
        return;
      }
      
      if (uniqueTitles.contains(epTitle.toLowerCase())) {
        _showSnackBar('Duplicate Title Error: "$epTitle" cannot be reused.');
        return;
      }
      uniqueTitles.add(epTitle.toLowerCase());

      final plainText = _quillControllers[i].document.toPlainText().trim();
      if (plainText.isEmpty) {
        _showSnackBar('Episode "$epTitle" copy content cannot be empty.');
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final List<Map<String, dynamic>> readyEpisodesArray = [];

      for (int i = 0; i < localEpisodes.length; i++) {
        final deltaJson = _quillControllers[i].document.toDelta().toJson();
        final converter = QuillDeltaToHtmlConverter(List<Map<String, dynamic>>.from(deltaJson));
        final htmlOutputStr = converter.convert();

        readyEpisodesArray.add({
          'id': localEpisodes[i]['id'] ?? (i + 1),
          'bookId': widget.book['id'],
          'authorId': widget.book['authorId'],
          'authorName': trimmedAuthor,
          'title': localEpisodes[i]['title'].toString().trim(),
          'description': localEpisodes[i]['description'].toString().trim(), // Include item inside update array data payload map
          'visibility': localEpisodes[i]['visibility'] ?? 'private',        // Include context element settings configuration tracking
          'content': htmlOutputStr,
        });
      }

      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.book['id'])
          .update({
        'title': trimmedTitle,
        'author': trimmedAuthor,
        'description': trimmedDesc,
        'visibility': _visibility,
        'coverImageUrl': _coverBase64,
        'episodeCount': readyEpisodesArray.length,
        'episodes': readyEpisodesArray,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar('Changes deployed successfully! 🚀');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('CRITICAL COMMIT FAILURE: $e');
      _showSnackBar('Exception encountered while updating document fields.');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Master Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_as_outlined),
            onPressed: isSaving ? null : saveCompleteBookChanges,
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 180,
                      width: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        image: _coverBase64 != null
                            ? DecorationImage(
                                image: MemoryImage(base64Decode(_coverBase64!.split(',').last)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _coverBase64 == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Tap poster element to swap cover imagery (Max 500KB)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Book Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorNameController,
                  decoration: const InputDecoration(labelText: 'Display Author Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Overview Abstract Synopsis', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _visibility,
                  decoration: const InputDecoration(labelText: 'Distribution Access Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public (Visible to all users)')),
                    DropdownMenuItem(value: 'private', child: Text('Private (Draft status)')),
                  ],
                  onChanged: (val) => setState(() => _visibility = val ?? 'public'),
                ),
                const SizedBox(height: 30),

                const Text('Manuscript Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),

                if (localEpisodes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Empty Manuscript. Add an episode below to begin typing.', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...localEpisodes.asMap().entries.map((entry) {
                    return _buildRichTextEpisodeCard(entry.key);
                  }),

                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _addNewEpisode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[100],
                    foregroundColor: Colors.blueGrey[900],
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add New Episode Chapter'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (isSaving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildRichTextEpisodeCard(int index) {
    final String? runningTitle = localEpisodes[index]['title'];
    final String? runningDescription = localEpisodes[index]['description'];
    final String runningVisibility = localEpisodes[index]['visibility'] ?? 'private';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    runningTitle != null && runningTitle.trim().isNotEmpty
                        ? '📖 $runningTitle'
                        : '📖 Episode ${index + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  onPressed: () => _deleteEpisode(index),
                )
              ],
            ),
            const SizedBox(height: 4),
            
            // 1. Title Input Element Block
            TextFormField(
              initialValue: runningTitle ?? '',
              decoration: const InputDecoration(labelText: 'Episode Title String', border: UnderlineInputBorder()),
              onChanged: (val) {
                setState(() {
                  localEpisodes[index]['title'] = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // 2. NEW: Episode Description Input Element Field 
            TextFormField(
              initialValue: runningDescription ?? '',
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Episode Short Summary Summary', border: UnderlineInputBorder()),
              onChanged: (val) {
                localEpisodes[index]['description'] = val;
              },
            ),
            const SizedBox(height: 12),

            // 3. NEW: Dropdown Input Block Selecting Episode Scope Status Specifier
            DropdownButtonFormField<String>(
              initialValue: runningVisibility,
              decoration: const InputDecoration(labelText: 'Episode Distribution Tier', border: UnderlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public (Available to readers)')),
                DropdownMenuItem(value: 'private', child: Text('Private (Draft Mode)')),
              ],
              onChanged: (val) {
                setState(() {
                  localEpisodes[index]['visibility'] = val ?? 'private';
                });
              },
            ),
            const SizedBox(height: 20),
            
            const Text('Episode Body Copy:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),

            quill.QuillSimpleToolbar(
              controller: _quillControllers[index],
              config: const quill.QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showSubscript: false,
                showSuperscript: false,
                multiRowsDisplay: false,
              ),
            ),
            Container(
              height: 220,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: quill.QuillEditor.basic(
                controller: _quillControllers[index],
                config: const quill.QuillEditorConfig(
                  scrollable: true,
                  autoFocus: false,
                  expands: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}