import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Shield & Terms',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Last updated: June 2026',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            
            _buildPolicyBlock(
              title: '1. Information We Collect',
              body: 'We collect account details provided directly by you during registration, including your name and email address. Furthermore, profile images uploaded to your account and original manuscript content are kept on secure cloud modules.',
            ),
            _buildPolicyBlock(
              title: '2. How We Use Data Structures',
              body: 'Your profile configuration data sets are processed purely to personalize your interface wrapper, verify user access rights across the publisher nodes, and synchronize reading progression tracks seamlessly across multiple devices.',
            ),
            _buildPolicyBlock(
              title: '3. Data Storage & Security Lifecycle',
              body: 'All files, book chapters, metadata metrics, and images are written directly via encrypted transport protocols to Cloud Firestore database nodes. Local user session contexts are managed carefully in local app memory partitions via SharedPreferences caches.',
            ),
            _buildPolicyBlock(
              title: '4. Third-Party Integrations',
              body: 'EpicTales depends directly upon Google Firebase instances for authentication handling and data persistence tasks. No data patterns are sold, distributed, or exposed to outside third-party marketing brokers.',
            ),
            
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            
            const Center(
              child: Text(
                'Questions? Contact support@lucidpages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF007BFF),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyBlock({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}