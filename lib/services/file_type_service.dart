enum DocumentType {
  pdf,
  unknown;

  /// Get display name for the document type
  String get displayName {
    switch (this) {
      case DocumentType.pdf:
        return 'PDF Document';
      case DocumentType.unknown:
        return 'Unknown Document';
    }
  }

  /// Get icon name for the document type
  String get iconName {
    switch (this) {
      case DocumentType.pdf:
        return 'picture_as_pdf';
      case DocumentType.unknown:
        return 'insert_drive_file';
    }
  }

  /// Get file extension
  String get extension {
    switch (this) {
      case DocumentType.pdf:
        return 'pdf';
      case DocumentType.unknown:
        return 'unknown';
    }
  }
}

class FileTypeService {
  /// Detect document type from file path or URL
  static DocumentType detectType(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return DocumentType.unknown;
    }

    // Remove query parameters if present (for URLs with signed params)
    String cleanPath = filePath;
    if (cleanPath.contains('?')) {
      cleanPath = cleanPath.split('?').first;
    }

    final lowerPath = cleanPath.toLowerCase();

    if (lowerPath.endsWith('.pdf')) {
      return DocumentType.pdf;
    }

    return DocumentType.unknown;
  }

  /// Check if file type is supported for in-app viewing
  static bool isSupported(DocumentType type) {
    return type == DocumentType.pdf;
  }

  /// Check if file requires native app to open
  static bool requiresNativeApp(DocumentType type) {
    return false; // Native app opening has been removed
  }

  /// Get MIME type for the document
  static String getMimeType(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return 'application/pdf';
      case DocumentType.unknown:
        return 'application/octet-stream';
    }
  }

  /// Get supported file extensions as filter
  static List<String> get supportedExtensions {
    return ['pdf'];
  }
}
