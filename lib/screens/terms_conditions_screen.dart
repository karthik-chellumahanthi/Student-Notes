import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using Student Notes, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using this app\'s particular services, you shall be subject to any posted guidelines or rules applicable to such services.',
            ),
            _buildSection(
              context,
              '2. Educational Purposes Only',
              'The content provided in this application, including notes, PDFs, and calculator tools, is for educational and informational purposes only. We do not guarantee the accuracy, completeness, or usefulness of this information.',
            ),
            _buildSection(
              context,
              '3. User Conduct',
              'You agree not to use the application in a way that may impair its performance, corrupt the content, or otherwise reduce the overall functionality of the app. You also agree not to compromise the security of the application or attempt to gain access to secured areas or sensitive information.',
            ),
            _buildSection(
              context,
              '4. Intellectual Property',
              'All materials provided on the app (unless specified otherwise or user-uploaded) remain the intellectual property of their respective creators. You may not distribute, modify, transmit, reuse, download, repost, copy, or use said materials for commercial purposes without permission.',
            ),
            _buildSection(
              context,
              '5. Limitation of Liability',
              'Student Notes and its developers shall not be liable for any special or consequential damages that result from the use of, or the inability to use, the materials on this application or the performance of the products.',
            ),
            _buildSection(
              context,
              '6. Changes to Terms',
              'We reserve the right to modify these terms from time to time at our sole discretion. Therefore, you should review these pages periodically. Your continued use of the Application after any such change constitutes your acceptance of the new Terms.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
