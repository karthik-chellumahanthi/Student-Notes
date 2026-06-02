import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentCacheService {
  static const int _cacheDurationMinutes = 30;

  /// Generate cache key from URL and file type
  static String _generateCacheKey(String url, String fileExtension) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;

    // Keep a short readable hint from the file name
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final lastSegment = segments.isNotEmpty ? segments.last : 'document';
    final fileHint = lastSegment
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final shortHint = fileHint.length > 40
        ? fileHint.substring(0, 40)
        : fileHint;

    // Add a deterministic short hash to prevent collisions
    final hash = _fnv1a32(path.toLowerCase());
    return '${shortHint}_$hash.$fileExtension';
  }

  /// Fast deterministic 32-bit hash (hex) for stable short file names
  static String _fnv1a32(String input) {
    var hash = 0x811C9DC5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Get the cache directory for all documents
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationCacheDirectory();
    final docCacheDir = Directory('${appDir.path}/document_cache');
    if (!await docCacheDir.exists()) {
      await docCacheDir.create(recursive: true);
    }
    return docCacheDir;
  }

  /// Get cached file if it exists and is not expired
  static Future<File?> getCachedFile(String url, String fileExtension) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(url, fileExtension);
      final cachedFile = File('${cacheDir.path}/$cacheKey');

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

  /// Download document from URL and cache it
  static Future<File> downloadAndCacheDocument(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download document: ${response.statusCode}');
      }

      // Extract file extension from URL or default to 'bin'
      final uri = Uri.tryParse(url);
      final pathSegments = uri?.path.split('.') ?? ['document'];
      final fileExtension =
          pathSegments.isNotEmpty && pathSegments.last.isNotEmpty
          ? pathSegments.last.toLowerCase()
          : 'bin';

      final cacheDir = await _getCacheDirectory();
      final cacheKey = _generateCacheKey(url, fileExtension);
      final docFile = File('${cacheDir.path}/$cacheKey');

      await docFile.writeAsBytes(response.bodyBytes);

      return docFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Get or download document (checks cache first)
  static Future<File> getDocument(String url) async {
    final uri = Uri.tryParse(url);
    final pathSegments = uri?.path.split('.') ?? ['document'];
    final fileExtension =
        pathSegments.isNotEmpty && pathSegments.last.isNotEmpty
        ? pathSegments.last.toLowerCase()
        : 'bin';

    final cachedFile = await getCachedFile(url, fileExtension);
    if (cachedFile != null) {
      return cachedFile;
    }
    return downloadAndCacheDocument(url);
  }

  /// Clear all cached documents
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

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      int size = 0;

      if (await cacheDir.exists()) {
        await cacheDir.list(recursive: true).forEach((file) {
          if (file is File) {
            size += file.lengthSync();
          }
        });
      }

      return size;
    } catch (e) {
      return 0;
    }
  }

  /// Format bytes to human readable format
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes == 0 ? 0 : (bytes / (1024)).abs().floor()).toInt();
    if (i > suffixes.length - 1) i = suffixes.length - 1;
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Power function for byte formatting
  static num pow(num base, int exponent) {
    if (base == 0) return 1;
    var result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base as int;
    }
    return result;
  }
}
