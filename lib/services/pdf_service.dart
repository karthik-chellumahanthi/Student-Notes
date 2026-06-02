import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// Get signed PDF URL from Firebase Function with retry logic
  ///
  /// Example: getPdfUrl("aid_1-1/beee/beee_unit_1.pdf")
  static Future<String> getPdfUrl(String path) async {
    int retries = 0;
    while (retries < _maxRetries) {
      try {
        // ✅ Verify user is authenticated first
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          throw Exception('User not authenticated - please login first');
        }

                
        // Call Cloud Function with authenticated user
        // Use region: us-central1 (or whatever region your function is deployed in)
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('getPdfUrl');
        final result = await callable.call({"path": path});

        return result.data['url'];
      } catch (e) {
        retries++;
        final errorMsg = e.toString();

        // Check if this is a temporary unavailable error
        if (errorMsg.contains('unavailable') && retries < _maxRetries) {
                    await Future.delayed(_retryDelay);
          continue;
        }

        // Final error after all retries
        throw Exception('Failed to get PDF URL: $e');
      }
    }
    throw Exception('Failed to get PDF URL after $_maxRetries retries');
  }

  /// Open PDF in default browser or app
  static Future<void> openPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL: $url');
      }
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Get and open PDF in one call
  ///
  /// Example: getAndOpenPdf("aid_1-1/beee/beee_unit_1.pdf")
  static Future<void> getAndOpenPdf(String path) async {
    try {
      final url = await getPdfUrl(path);
      await openPdf(url);
    } catch (e) {
      throw Exception('Failed to get and open PDF: $e');
    }
  }
}
