import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdfService {
  static const String _workerUrl = 'https://student-notes-uploader.studentnotes-uploads.workers.dev';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// Get signed PDF URL from Cloudflare Worker with Firebase Auth verification and retry logic
  ///
  /// Example: getPdfUrl("aid_1-1/beee/beee_unit_1.pdf")
  static Future<String> getPdfUrl(String path) async {
    int retries = 0;
    while (retries < _maxRetries) {
      try {
        // ✅ Verify user is authenticated in Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated - please login first');
        }

        // Fetch Firebase ID Token for server-side verification in Worker
        final idToken = await user.getIdToken();

        final response = await http.post(
          Uri.parse('$_workerUrl/get-pdf-url'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
            'X-App-Key': dotenv.env['X_APP_KEY'] ?? '',
          },
          body: jsonEncode({
            'path': path,
          }),
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          throw Exception(body['error'] ?? 'Unauthorized access');
        }

        if (response.statusCode != 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          throw Exception(body['error'] ?? 'Failed to get PDF URL (${response.statusCode})');
        }

        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? url = data['url'];

        if (url == null || url.isEmpty) {
          throw Exception('Received empty URL from server');
        }

        return url;
      } catch (e) {
        retries++;
        final errorMsg = e.toString();

        // Retry on temporary network connection hiccups
        if ((errorMsg.contains('unavailable') || errorMsg.contains('SocketException')) && retries < _maxRetries) {
          await Future.delayed(_retryDelay);
          continue;
        }

        // Re-throw after retries
        throw Exception('Failed to get PDF URL: $e');
      }
    }
    throw Exception('Failed to get PDF URL after $_maxRetries retries');
  }
}
