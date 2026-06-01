import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// Submits the valid feedback text payload straight to Cloud Firestore
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Authentication state invalid. Please sign in again.', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Structure telemetry data bundle cleanly
      final Map<String, dynamic> feedbackData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email ?? 'anonymous',
        'feedbackText': _feedbackController.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
        'platform': 'Flutter/Android/iOS',
      };

      // Push payload block asynchronously directly into your cloud root collection
      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (!mounted) return;
      _showSnackBar('Thank you! Your feedback has been logged securely. 🚀', isError: false);
      
      // Auto-pop current view hierarchy stack back to user profile dashboard
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Transmission error logging feedback entry: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on background taps
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We value your insights',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell us what you like, report bugs, or request features to improve Lucid Pages.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  
                  // Interactive multiline input text field wrapper container
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 6,
                    maxLength: 1000,
                    enabled: !_isSubmitting,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Type your feedback message text body here...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007BFF), width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Feedback description copy cannot be blank.';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide a more detailed comment (min. 10 characters).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Terminal Button Node
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Transmit Feedback Data',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}