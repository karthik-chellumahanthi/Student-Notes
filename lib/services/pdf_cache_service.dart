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

  /// Download PDF from URL and cache it
  static Future<File> downloadAndCachePdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }

      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(url);
      final pdfFile = File('${cacheDir.path}/$cacheKey.pdf');

      await pdfFile.writeAsBytes(response.bodyBytes);

      return pdfFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Get or download PDF (checks cache first)
  static Future<File> getPdf(String url) async {
    final cachedFile = await getCachedFile(url);
    if (cachedFile != null) {
      return cachedFile;
    }
    return downloadAndCachePdf(url);
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
      final pdfFiles = files.whereType<File>().where(
        (f) => f.path.endsWith('.pdf'),
      );

      int totalSize = 0;
      int validFiles = 0;
      int expiredFiles = 0;

      for (final file in pdfFiles) {
        final size = await file.length();
        totalSize += size;

        final lastModified = await file.lastModified();
        final cacheAge = DateTime.now().difference(lastModified);

        if (cacheAge.inMinutes > _cacheDurationMinutes) {
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
