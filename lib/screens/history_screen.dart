import 'package:flutter/material.dart';
import 'dart:io';
import '../services/history_service.dart';
import '../services/file_type_service.dart';
import 'pdf_viewer_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  late HistoryService _historyService;
  List<HistoryItem> _allHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHistory();
    }
  }

  Future<void> _initializeHistory() async {
    _historyService = await HistoryService.getInstance();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final allHistory = await _historyService.getHistory();

      if (mounted) {
        setState(() {
          _allHistory = allHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeItem(String id) async {
    await _historyService.removeFromHistory(id);
    _loadHistory();
  }

  String _formatTime(DateTime dateTime) {
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

  Future<void> _openHistoryItem(HistoryItem item) async {
    try {
      // Detect file type
      var docType = FileTypeService.detectType(item.filePath);
      if (docType == DocumentType.unknown) {
        docType = FileTypeService.detectType(item.name);
      }
      // Default to PDF since app is PDF-only and extensions may be stripped
      if (docType == DocumentType.unknown) {
        docType = DocumentType.pdf;
      }

      if (!mounted) {
        return;
      }

      // Check if it's a network file (URL) or local file
      bool isNetworkFile =
          item.filePath.startsWith('http://') ||
          item.filePath.startsWith('https://');

      // For local files, verify they exist
      if (!isNetworkFile) {
        final file = File(item.filePath);
        if (!file.existsSync()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File not found: ${item.name}'),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Remove',
                  onPressed: () {
                    _removeItem(item.id);
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      Widget screen;
      if (docType == DocumentType.pdf) {
        screen = isNetworkFile
            ? PDFViewerScreen.network(
                url: item.filePath,
                fileName: item.name,
                subject: item.subject,
              )
            : PDFViewerScreen.file(
                filePath: item.filePath,
                fileName: item.name,
                subject: item.subject,
              );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsupported file type'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
      onRefresh: _loadHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recently Opened",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadHistory,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_allHistory.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No files opened yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open files from notes or downloads\nto see them here',
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
                  itemCount: _allHistory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _allHistory[index];

                    // Format display name
                    String displayName = item.name;
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


                    // Detect file type for proper icon
                    var fileType = FileTypeService.detectType(item.filePath);
                    if (fileType == DocumentType.unknown) {
                      fileType = FileTypeService.detectType(item.name);
                    }
                    // Default to PDF since app is PDF-only
                    if (fileType == DocumentType.unknown) {
                      fileType = DocumentType.pdf;
                    }

                    IconData iconData;
                    Color iconColor;
                    if (fileType == DocumentType.pdf) {
                      iconData = Icons.picture_as_pdf;
                      iconColor = Colors.red[400]!;
                    } else {
                      iconData = Icons.file_present;
                      iconColor = Colors.grey[500]!;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openHistoryItem(item),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(iconData, color: iconColor, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.subject.isNotEmpty)
                                        Text(
                                          item.subject,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(item.openedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Remove',
                                            style: TextStyle(
                                              color: Colors.red[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _removeItem(item.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
