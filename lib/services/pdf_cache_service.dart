import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfCacheService {
  static const int _cacheDurationMinutes = 30;

  /// Generate cache key from URL
  static String _generateCacheKey(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;

    // Keep a short readable hint from the file name.
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final lastSegment = segments.isNotEmpty ? segments.last : 'pdf';
    final fileHint = lastSegment
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final shortHint = fileHint.length > 40
        ? fileHint.substring(0, 40)
        : fileHint;

    // Add a deterministic short hash to prevent collisions.
    final hash = _fnv1a32(path.toLowerCase());
    return '${shortHint}_$hash';
  }

  /// Fast deterministic 32-bit hash (hex) for stable short file names.
  static String _fnv1a32(String input) {
    var hash = 0x811C9DC5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Get the cache directory for PDFs
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationCacheDirectory();
    final pdfCacheDir = Directory('${appDir.path}/pdf_cache');
    if (!await pdfCacheDir.exists()) {
      await pdfCacheDir.create(recursive: true);
    }
    return pdfCacheDir;
  }

  /// Get cached file if it exists and is not expired
  static Future<File?> getCachedFile(String url) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(url);
      final cachedFile = File('${cacheDir.path}/$cacheKey.pdf');

      if (!await cachedFile.exists()) {
        return null;
      }

      final lastModified = await cachedFile.lastModified();
      final cacheAge = DateTime.now().difference(lastModified);

      if (cacheAge.inMinutes > _cacheDurationMinutes) {
        await cachedFile.delete();
        return null;
      }

      return cachedFile;
    } catch (e) {
      return null;
    }
  }

  static final Map<String, Future<File>> _activeDownloads = {};

  /// Download PDF from URL and cache it
  static Future<File> downloadAndCachePdf(String url, {void Function(double)? onProgress}) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(url);
      final tempFile = File('${cacheDir.path}/$cacheKey.temp');
      final pdfFile = File('${cacheDir.path}/$cacheKey.pdf');

      int existingBytes = 0;
      if (await tempFile.exists()) {
        existingBytes = await tempFile.length();
        // Check if the temp file is older than 24 hours, if so delete it instead of resuming
        final lastModified = await tempFile.lastModified();
        if (DateTime.now().difference(lastModified).inHours > 24) {
          await tempFile.delete();
          existingBytes = 0;
        }
      }

      final request = http.Request('GET', Uri.parse(url));
      if (existingBytes > 0) {
        request.headers['Range'] = 'bytes=$existingBytes-';
      }

      final response = await http.Client().send(request);
      
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      bool isPartial = response.statusCode == 206;
      if (!isPartial) {
        // Server doesn't support Range or sending full file.
        existingBytes = 0;
      }

      final contentLength = response.contentLength;
      final totalExpectedBytes = existingBytes + (contentLength ?? 0);
      int bytesDownloaded = existingBytes;

      final sink = tempFile.openWrite(mode: isPartial ? FileMode.append : FileMode.write);

      await for (final chunk in response.stream) {
        bytesDownloaded += chunk.length;
        sink.add(chunk);
        
        if (totalExpectedBytes > 0 && onProgress != null) {
          onProgress(bytesDownloaded / totalExpectedBytes);
        }
      }

      await sink.close();
      
      // Rename temp file to actual pdf file only after complete download
      if (await tempFile.exists()) {
        await tempFile.rename(pdfFile.path);
      }

      return pdfFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Get or download PDF (checks cache first)
  static Future<File> getPdf(String url, {void Function(double)? onProgress}) async {
    final cachedFile = await getCachedFile(url);
    if (cachedFile != null) {
      if (onProgress != null) onProgress(1.0);
      return cachedFile;
    }

    // If a download for this URL is already in progress, wait for it to finish
    if (_activeDownloads.containsKey(url)) {
      final file = await _activeDownloads[url]!;
      if (onProgress != null) onProgress(1.0);
      return file;
    }

    // Otherwise, start a new download and track it
    final downloadFuture = downloadAndCachePdf(url, onProgress: onProgress);
    _activeDownloads[url] = downloadFuture;

    try {
      final file = await downloadFuture;
      _activeDownloads.remove(url);
      return file;
    } catch (e) {
      _activeDownloads.remove(url);
      rethrow;
    }
  }

  /// Clear all cached PDFs
  static Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors when clearing cache
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = await cacheDir.list().toList();
      
      // Clean up old temp files
      final tempFiles = files.whereType<File>().where((f) => f.path.endsWith('.temp'));
      for (final tempFile in tempFiles) {
        final lastModified = await tempFile.lastModified();
        if (DateTime.now().difference(lastModified).inHours > 24) {
          try { await tempFile.delete(); } catch (_) {}
        }
      }

      final pdfFiles = files.whereType<File>().where(
        (f) => f.path.endsWith('.pdf'),
      ).toList();

      final stats = await Future.wait(pdfFiles.map((file) async {
        final size = await file.length();
        final lastModified = await file.lastModified();
        final cacheAge = DateTime.now().difference(lastModified);
        final isExpired = cacheAge.inMinutes > _cacheDurationMinutes;
        return {'size': size, 'isExpired': isExpired};
      }));

      int totalSize = 0;
      int validFiles = 0;
      int expiredFiles = 0;

      for (final stat in stats) {
        totalSize += stat['size'] as int;
        if (stat['isExpired'] as bool) {
          expiredFiles++;
        } else {
          validFiles++;
        }
      }

      return {
        'totalFiles': pdfFiles.length,
        'validFiles': validFiles,
        'expiredFiles': expiredFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {};
    }
  }
}
