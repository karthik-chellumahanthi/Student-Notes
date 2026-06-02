import 'dart:io';
import 'package:flutter/material.dart';
import '../services/downloads_service.dart';
import '../services/history_service.dart';
import '../services/file_type_service.dart';
import 'pdf_viewer_screen.dart';
import 'document_viewer_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late DownloadsService _downloadsService;
  late HistoryService _historyService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadsService = DownloadsService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _historyService = await HistoryService.getInstance();
      await _downloadsService.initialize();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDownloads() async {
    setState(() {
      _isLoading = true;
    });
    await _downloadsService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(String id, String name) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Delete Download?'),
              content: Text('Are you sure you want to delete "$name"?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed && mounted) {
      try {
        await _downloadsService.deleteDownload(id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download deleted'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {}
  }

  Widget _getViewerScreen(
    String filePath,
    String fileName, {
    String subject = '',
  }) {
    // Try to get extension from filePath first, then from fileName
    String extension = '';

    if (filePath.contains('.')) {
      extension = filePath.split('.').last.toLowerCase();
    } else if (fileName.contains('.')) {
      extension = fileName.split('.').last.toLowerCase();
    }

    // For PDF files
    if (extension == 'pdf') {
      return PDFViewerScreen.file(
        filePath: filePath,
        fileName: fileName,
        subject: subject,
      );
    }

    // For unknown or other formats, use the file name for detection
    final docType = FileTypeService.detectType(fileName);

    if (docType == DocumentType.pdf) {
      return PDFViewerScreen.file(
        filePath: filePath,
        fileName: fileName,
        subject: subject,
      );
    } else {
      // Default to document viewer
      return DocumentViewerScreen.file(
        filePath: filePath,
        fileName: fileName,
        subject: subject,
      );
    }
  }

  Future<void> _openDownload(DownloadedFile download) async {
    try {
      // Add to history
      await _historyService.addToHistory(
        id: download.id,
        name: download.name,
        type: 'note',
        filePath: download.filePath,
        subject: download.subject,
      );

      // Open appropriate viewer based on file format
      if (mounted) {
        // Verify file exists
        final file = File(download.filePath);
        if (!file.existsSync()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found. Please redownload.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _getViewerScreen(
              download.filePath,
              download.name,
              subject: download.subject,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDownloads,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Downloaded Materials",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_downloadsService.downloads.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Downloaded Materials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download units from the materials section\nto access them offline',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _downloadsService.downloads.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final download = _downloadsService.downloads[index];

                    // Format display name for legacy files that saved the path as name
                    String displayName = download.name;
                    if (displayName.contains('%2F')) {
                      displayName = Uri.decodeComponent(
                        displayName,
                      ).split('/').last;
                    }
                    if (displayName.toLowerCase().endsWith('.pdf')) {
                      displayName = displayName.substring(
                        0,
                        displayName.length - 4,
                      );
                    }
                    if (displayName.toLowerCase().endsWith('.docx') ||
                        displayName.toLowerCase().endsWith('.pptx')) {
                      displayName = displayName.substring(
                        0,
                        displayName.length - 5,
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openDownload(download),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red[400],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (download.subject.isNotEmpty)
                                            Text(
                                              download.subject,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(download.downloadedAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Material(
                                      color: Colors.blueGrey[600],
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _openDownload(download),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 20,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.open_in_new,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Open',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.red[400]!,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          onTap: () => _deleteDownload(
                                            download.id,
                                            download.name,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 20,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color: Colors.red[500],
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red[500],
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
