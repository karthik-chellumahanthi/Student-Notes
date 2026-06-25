import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'submission_history_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _selectedFile;
  bool _isUploading = false;
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0.0);
  
  // The Cloudflare Worker URL
  final String _workerUrl = 'https://student-notes-uploader.studentnotes-uploads.workers.dev';

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'rtf', 'csv', 'jpg', 'jpeg', 'png', 'zip', 'rar', '7z'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // Check file size (100MB limit)
        int sizeInBytes = file.lengthSync();
        double sizeInMb = sizeInBytes / (1024 * 1024);
        
        if (sizeInMb > 100) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File must be less than 100MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  // Rate limiting is now handled securely by the Cloudflare Worker backend.

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to upload')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });
    _uploadProgress.value = 0.1;

    try {
      // Upload File to Cloudflare Worker
      final fileName = _selectedFile!.path.split('/').last;
      final safeFileName = "${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}";

      final fileLength = await _selectedFile!.length();
      
      final request = http.StreamedRequest('PUT', Uri.parse('$_workerUrl/upload/$safeFileName'));
      request.headers['Content-Length'] = fileLength.toString();
      request.headers['Content-Type'] = 'application/octet-stream';
      request.headers['X-User-ID'] = user.uid; // Required for Cloudflare KV rate limiting
      request.headers['X-App-Key'] = dotenv.env['X_APP_KEY'] ?? '';

      int bytesUploaded = 0;
      DateTime lastUpdateTime = DateTime.now();
      final stream = _selectedFile!.openRead();
      
      stream.listen(
        (chunk) {
          bytesUploaded += chunk.length;
          final now = DateTime.now();
          
          if (mounted && (now.difference(lastUpdateTime).inMilliseconds >= 1000 || bytesUploaded == fileLength)) {
            lastUpdateTime = now;
            // Update the ValueNotifier instead of calling setState
            _uploadProgress.value = (bytesUploaded / fileLength) * 0.99;
          }
          request.sink.add(chunk);
        },
        onDone: () {
          request.sink.close();
        },
        onError: (e) {
          request.sink.addError(e);
          request.sink.close();
        },
        cancelOnError: true,
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 429) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily limit of 5 uploads reached. Please try again tomorrow.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to upload file: $responseBody');
      }

      final urlData = jsonDecode(responseBody);
      final fileUrl = urlData['fileUrl'];

      _uploadProgress.value = 0.8;

      // Save to Firestore
      final submissionRef = await FirebaseFirestore.instance.collection('submissions').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fileUrl': fileUrl,
        'fileName': fileName,
        'userId': user.uid,
        'userEmail': user.email,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Trigger Email Notification via Worker
      final emailResponse = await http.post(
        Uri.parse('$_workerUrl/send-notification'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Key': dotenv.env['X_APP_KEY'] ?? '',
        },
        body: jsonEncode({
          'submissionId': submissionRef.id,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'fileUrl': fileUrl,
          'fileName': fileName,
          'userEmail': user.email ?? 'Unknown',
        }),
      );

      debugPrint("Email Response Status: ${emailResponse.statusCode}");
      debugPrint("Email Response Body: ${emailResponse.body}");

      _uploadProgress.value = 1.0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Materials'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubmissionHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  ValueListenableBuilder<double>(
                    valueListenable: _uploadProgress,
                    builder: (context, progress, child) {
                      return Text(
                        'Uploading... ${(progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Please do not close the app'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can submit notes, question papers, or materials. Limit: 5 files per day, max 100MB each.',
                              style: TextStyle(
                                color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Title',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Data Structures Unit 1 Notes',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add details like Regulation, Year, etc.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Attachment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFile != null ? Colors.green : Colors.grey.shade400,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                              size: 48,
                              color: _selectedFile != null ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile != null 
                                ? _selectedFile!.path.split('/').last 
                                : 'Tap to select a file (Max 100MB)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                                color: _selectedFile != null 
                                  ? (isDark ? Colors.green.shade300 : Colors.green.shade700) 
                                  : null,
                              ),
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${(_selectedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7280),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _uploadProgress.dispose();
    super.dispose();
  }
}
