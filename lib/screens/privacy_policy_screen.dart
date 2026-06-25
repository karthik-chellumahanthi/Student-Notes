import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
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
              '1. Information Collection',
              'We collect minimal information required for the operation of Student Notes. This may include user preferences and locally stored data (like download history or calculator inputs). We do not collect personally identifiable information unless explicitly provided by you for specific features.',
            ),
            _buildSection(
              context,
              '2. Data Usage',
              'The data collected is used solely to provide and improve the services offered within the app, such as personalizing your experience, tracking attendance locally, or managing your downloaded materials.',
            ),
            _buildSection(
              context,
              '3. Data Storage and Security',
              'Your data (such as downloaded PDFs, notes, and attendance records) is stored locally on your device or synced with secure cloud services to enable app functionality. We implement standard security measures to protect your data.',
            ),
            _buildSection(
              context,
              '4. Third-Party Services',
              'The app may use third-party services that may collect information used to identify you. These third-party services have their own Privacy Policies addressing how they handle such information.',
            ),
            _buildSection(
              context,
              '5. Changes to This Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
            ),
            _buildSection(
              context,
              '6. Contact Us',
              'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us.',
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
