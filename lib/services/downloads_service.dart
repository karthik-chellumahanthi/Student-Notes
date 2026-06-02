import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedFile {
  final String id;
  final String name;
  final String subject;
  final String semester;
  final String branch;
  final String unitNumber;
  final String type; // 'unit_notes', 'question_paper'
  final DateTime downloadedAt;
  final String filePath;
  final int fileSize;

  DownloadedFile({
    required this.id,
    required this.name,
    required this.subject,
    required this.semester,
    required this.branch,
    required this.unitNumber,
    required this.type,
    required this.downloadedAt,
    required this.filePath,
    required this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'semester': semester,
      'branch': branch,
      'unitNumber': unitNumber,
      'type': type,
      'downloadedAt': downloadedAt.toIso8601String(),
      'filePath': filePath,
      'fileSize': fileSize,
    };
  }

  factory DownloadedFile.fromMap(Map<String, dynamic> map) {
    return DownloadedFile(
      id: map['id'],
      name: map['name'],
      subject: map['subject'],
      semester: map['semester'],
      branch: map['branch'],
      unitNumber: map['unitNumber'] ?? '',
      type: map['type'],
      downloadedAt: DateTime.parse(map['downloadedAt']),
      filePath: map['filePath'],
      fileSize: map['fileSize'],
    );
  }
}

class DownloadsService {
  static final DownloadsService _instance = DownloadsService._internal();

  factory DownloadsService() {
    return _instance;
  }

  DownloadsService._internal();

  final List<DownloadedFile> _downloads = [];
  late SharedPreferences _prefs;

  List<DownloadedFile> get downloads => _downloads;

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await loadDownloads();
  }

  /// Get downloads directory (app-specific persistent storage)
  /// Files are stored in the app's document directory which persists across app updates and restarts
  Future<Directory> _getDownloadsDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory downloadsDir = Directory('${appDocDir.path}/downloads');

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    return downloadsDir;
  }

  /// Add a new downloaded file
  Future<DownloadedFile> addDownload({
    required String name,
    required String subject,
    required String semester,
    required String branch,
    required String unitNumber,
    required String type,
    required List<int> fileBytes,
  }) async {
    try {
      final downloadDir = await _getDownloadsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name';
      final file = File('${downloadDir.path}/$fileName');

      await file.writeAsBytes(fileBytes);

      final downloadedFile = DownloadedFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        subject: subject,
        semester: semester,
        branch: branch,
        unitNumber: unitNumber,
        type: type,
        downloadedAt: DateTime.now(),
        filePath: file.path,
        fileSize: fileBytes.length,
      );

      _downloads.add(downloadedFile);
      await _saveDownloadsToPrefs();
      return downloadedFile;
    } catch (e) {
      throw Exception('Failed to save download: $e');
    }
  }

  /// Check if a file is already downloaded
  bool isDownloaded(String subject, String unitNumber) {
    return _downloads.any(
      (d) => d.subject == subject && d.unitNumber == unitNumber,
    );
  }

  /// Get a downloaded file by subject and unit number
  DownloadedFile? getDownloadedFile(String subject, String unitNumber) {
    try {
      return _downloads.firstWhere(
        (d) => d.subject == subject && d.unitNumber == unitNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Delete a download
  Future<void> deleteDownload(String id) async {
    try {
      final index = _downloads.indexWhere((d) => d.id == id);
      if (index != -1) {
        final file = File(_downloads[index].filePath);
        if (file.existsSync()) {
          await file.delete();
        }
        _downloads.removeAt(index);
        await _saveDownloadsToPrefs();
      }
    } catch (e) {
      throw Exception('Failed to delete download: $e');
    }
  }

  /// Save downloads metadata to SharedPreferences
  Future<void> _saveDownloadsToPrefs() async {
    try {
      final downloadsJson = jsonEncode(
        _downloads.map((d) => d.toMap()).toList(),
      );
      await _prefs.setString('downloads_metadata', downloadsJson);
    } catch (e) {
      // Silently fail
    }
  }

  /// Get file size in readable format
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.toString().length / 3).ceil();
    var size = (bytes / pow(1024, i - 1)).toStringAsFixed(2);
    return '$size ${suffixes[i - 1]}';
  }

  /// Load downloads from storage (for persistence)
  /// This method verifies that all stored file references still exist
  /// and removes stale entries if files are missing
  Future<void> loadDownloads() async {
    try {
      final downloadsJson = _prefs.getString('downloads_metadata');

      _downloads.clear();
      bool hasChanges = false;

      if (downloadsJson != null && downloadsJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(downloadsJson);
        for (var item in decodedList) {
          final downloadedFile = DownloadedFile.fromMap(
            Map<String, dynamic>.from(item),
          );
          // Verify file still exists on the device
          if (File(downloadedFile.filePath).existsSync()) {
            _downloads.add(downloadedFile);
          } else {
            // File is missing, mark that we need to update metadata
            hasChanges = true;
          }
        }
      }

      // If any files were deleted or missing, update the stored metadata
      if (hasChanges) {
        await _saveDownloadsToPrefs();
      }
    } catch (e) {
      // Error loading downloads, silently fail
    }
  }

  /// Update the file path for an encrypted download
  Future<void> updateDownloadPath(String downloadId, String newFilePath) async {
    try {
      final index = _downloads.indexWhere((d) => d.id == downloadId);
      if (index >= 0) {
        final old = _downloads[index];
        _downloads[index] = DownloadedFile(
          id: old.id,
          name: old.name,
          subject: old.subject,
          semester: old.semester,
          branch: old.branch,
          unitNumber: old.unitNumber,
          type: old.type,
          downloadedAt: old.downloadedAt,
          filePath: newFilePath,
          fileSize: old.fileSize,
        );
        await _saveDownloadsToPrefs();
      }
    } catch (e) {
      // Handle error silently for legacy downloads
    }
  }
}

int pow(int base, int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
