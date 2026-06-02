import 'package:http/http.dart' as http;
import 'downloads_service.dart';
import 'encryption_service.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();

  factory DownloadManager() {
    return _instance;
  }

  DownloadManager._internal();

  final DownloadsService _downloadsService = DownloadsService();
  final EncryptionService _encryptionService = EncryptionService();
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

  /// Get download progress for a specific subject+unit
  double getProgress(String subject, String unitNumber) {
    return _downloadProgress['$subject-$unitNumber'] ?? 0.0;
  }

  /// Check if currently downloading
  bool isDownloading(String subject, String unitNumber) {
    return _isDownloading['$subject-$unitNumber'] ?? false;
  }

  /// Extract filename with extension from URL
  String _extractFilenameFromUrl(String url, String fallbackName) {
    try {
      // Remove query parameters
      String cleanUrl = url.split('?').first;
      
      // Decode URL to handle %2F etc.
      cleanUrl = Uri.decodeFull(cleanUrl);

      // Get the last part of the URL path
      String lastPart = cleanUrl.split('/').last;

      // Check if it has a file extension
      if (lastPart.contains('.')) {
        String extension = lastPart.split('.').last;
                
        // Ensure the fallback name has the correct extension
        if (!fallbackName.toLowerCase().endsWith('.$extension')) {
          return '$fallbackName.$extension';
        }
        return fallbackName;
      }

      // If no extension in URL, check if fallback has one
      if (fallbackName.contains('.')) {
                return fallbackName;
      }

      // Default to fallback name
            return fallbackName;
    } catch (e) {
            return fallbackName;
    }
  }

  /// Download file from URL and save to internal storage
  Future<DownloadedFile?> downloadFile({
    required String fileUrl,
    required String fileName,
    required String subject,
    required String semester,
    required String branch,
    required String unitNumber,
    required String type,
    required Function(double progress) onProgress,
  }) async {
    try {
      final key = '$subject-$unitNumber';
      _isDownloading[key] = true;
      _downloadProgress[key] = 0.0;

      // Download the file
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        final fileBytes = response.bodyBytes;

        // Extract filename with extension from URL
        final actualFileName = _extractFilenameFromUrl(fileUrl, fileName);

        // Add to downloads service
        final downloadedFile = await _downloadsService.addDownload(
          name: actualFileName,
          subject: subject,
          semester: semester,
          branch: branch,
          unitNumber: unitNumber,
          type: type,
          fileBytes: fileBytes,
        );

        // 🔒 ENCRYPT the downloaded file
        try {
          await _encryptionService.initialize();
          final encryptedFilePath = await _encryptionService.encryptFile(
            downloadedFile.filePath,
          );

          
          // Create a new DownloadedFile with encrypted path
          final encryptedFile = DownloadedFile(
            id: downloadedFile.id,
            name: downloadedFile.name,
            subject: downloadedFile.subject,
            semester: downloadedFile.semester,
            branch: downloadedFile.branch,
            unitNumber: downloadedFile.unitNumber,
            type: downloadedFile.type,
            downloadedAt: downloadedFile.downloadedAt,
            filePath: encryptedFilePath,
            fileSize: downloadedFile.fileSize,
          );

          // Update in downloads service
          _downloadsService.updateDownloadPath(
            downloadedFile.id,
            encryptedFilePath,
          );

          _downloadProgress[key] = 1.0;
          onProgress(1.0);

          _isDownloading[key] = false;
          return encryptedFile;
        } catch (e) {
                    // Continue without encryption rather than failing the download
          _downloadProgress[key] = 1.0;
          onProgress(1.0);

          _isDownloading[key] = false;
          return downloadedFile;
        }
      } else {
        _isDownloading[key] = false;
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      _isDownloading['$subject-$unitNumber'] = false;
      rethrow;
    }
  }

  /// Stream download progress from URL (for future implementation with streaming)
  Future<DownloadedFile?> downloadFileWithProgress({
    required String fileUrl,
    required String fileName,
    required String subject,
    required String semester,
    required String branch,
    required String unitNumber,
    required String type,
    required Function(double progress) onProgress,
  }) async {
    try {
      final key = '$subject-$unitNumber';
      _isDownloading[key] = true;
      _downloadProgress[key] = 0.0;

      final request = http.Request('GET', Uri.parse(fileUrl));
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? 0;
        int receivedBytes = 0;
        final List<int> fileBytes = [];
        DateTime lastUpdateTime = DateTime.now();

        await for (List<int> chunk in streamedResponse.stream) {
          receivedBytes += chunk.length;
          fileBytes.addAll(chunk);
          final progress = contentLength > 0
              ? receivedBytes / contentLength
              : 0.0;
          _downloadProgress[key] = progress;
          
          final now = DateTime.now();
          // Update progress every 1 second or when complete to prevent flickering
          if (now.difference(lastUpdateTime).inMilliseconds >= 1000 || progress == 1.0) {
            onProgress(progress);
            lastUpdateTime = now;
          }
        }

        // Extract filename with extension from URL
        final actualFileName = _extractFilenameFromUrl(fileUrl, fileName);

        // Add to downloads service
        final downloadedFile = await _downloadsService.addDownload(
          name: actualFileName,
          subject: subject,
          semester: semester,
          branch: branch,
          unitNumber: unitNumber,
          type: type,
          fileBytes: fileBytes,
        );

        // 🔒 ENCRYPT the downloaded file
        try {
          await _encryptionService.initialize();
          final encryptedFilePath = await _encryptionService.encryptFile(
            downloadedFile.filePath,
          );

          
          // Create a new DownloadedFile with encrypted path
          final encryptedFile = DownloadedFile(
            id: downloadedFile.id,
            name: downloadedFile.name,
            subject: downloadedFile.subject,
            semester: downloadedFile.semester,
            branch: downloadedFile.branch,
            unitNumber: downloadedFile.unitNumber,
            type: downloadedFile.type,
            downloadedAt: downloadedFile.downloadedAt,
            filePath: encryptedFilePath,
            fileSize: downloadedFile.fileSize,
          );

          // Update in downloads service
          _downloadsService.updateDownloadPath(
            downloadedFile.id,
            encryptedFilePath,
          );

          _downloadProgress[key] = 1.0;
          onProgress(1.0);

          _isDownloading[key] = false;
          return encryptedFile;
        } catch (e) {
                    // Continue without encryption rather than failing the download
          _downloadProgress[key] = 1.0;
          onProgress(1.0);

          _isDownloading[key] = false;
          return downloadedFile;
        }
      } else {
        _isDownloading[key] = false;
        throw Exception(
          'Failed to download file: ${streamedResponse.statusCode}',
        );
      }
    } catch (e) {
      _isDownloading['$subject-$unitNumber'] = false;
      rethrow;
    }
  }

  /// Cancel download (not yet downloaded in this simple implementation)
  void cancelDownload(String subject, String unitNumber) {
    final key = '$subject-$unitNumber';
    _isDownloading[key] = false;
    _downloadProgress[key] = 0.0;
  }
}
