import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_service.dart';
import '../services/download_manager.dart';
import '../services/downloads_service.dart';
import '../services/history_service.dart';
import '../services/file_type_service.dart';
import '../widgets/app_scaffold.dart';
import 'document_viewer_screen.dart';
import 'pdf_viewer_screen.dart';

class UnitsScreen extends StatefulWidget {
  final String branchId;
  final String subjectId;
  final String subjectName;

  const UnitsScreen({
    super.key,
    required this.branchId,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  late DownloadManager _downloadManager;
  late DownloadsService _downloadsService;
  late HistoryService _historyService;
  final Set<String> _downloadingUnits = {};
  final Map<String, ValueNotifier<double>> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _downloadManager = DownloadManager();
    _downloadsService = DownloadsService();
    _initializeHistoryService();
  }

  Future<void> _initializeHistoryService() async {
    _historyService = await HistoryService.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      currentIndex: 0,
      onBottomNavTap: (index) {
        Navigator.of(context).pop(index);
      },
      showDrawer: false,
      showBottomNav: false,
      body: Column(
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Unit",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Subject: ${widget.subjectName}",
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.black54),
                ),
              ],
            ),
          ),

          /// Firestore FutureBuilder for Units
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('branches')
                  .doc(widget.branchId)
                  .collection('subjects')
                  .doc(widget.subjectId)
                  .collection('units')
                  .get(const GetOptions(source: Source.serverAndCache)),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            "No Internet Connection",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please check your network and try again.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  if (snapshot.hasData && snapshot.data!.metadata.isFromCache) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, size: 64, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No Internet Connection",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Please connect to the internet to load units.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[500] : Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No Units Found",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    String unitTitle =
                        doc['title'] as String? ?? 'Unit ${index + 1}';
                    String unitPath = doc['path'] as String? ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            _openPdfUnit(unitPath, unitTitle);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        unitTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to view PDF',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildDownloadButton(
                                      context,
                                      unitTitle,
                                      unitPath,
                                      widget.subjectName,
                                      '${index + 1}',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    String unitTitle,
    String unitPath,
    String subjectName,
    String unitNumber,
  ) {
    final key = '$subjectName-$unitNumber';
    final isDownloading = _downloadingUnits.contains(key);
    final isDownloaded = _downloadsService.isDownloaded(
      subjectName,
      unitNumber,
    );

    if (isDownloading) {
      final notifier = _downloadProgress[key] ?? ValueNotifier<double>(0.0);
      return SizedBox(
        width: 32,
        height: 32,
        child: ValueListenableBuilder<double>(
          valueListenable: notifier,
          builder: (context, progress, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  backgroundColor: Colors.grey[300],
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    if (isDownloaded) {
      return GestureDetector(
        onTap: () => _openDownloadedFile(context, subjectName, unitNumber),
        child: Icon(Icons.download_done, color: Colors.green[600], size: 32),
      );
    }

    return GestureDetector(
      onTap: () =>
          _downloadUnit(context, unitPath, unitTitle, subjectName, unitNumber),
      child: Icon(Icons.download_outlined, color: Colors.grey[600], size: 32),
    );
  }

  Future<void> _downloadUnit(
    BuildContext context,
    String unitPath,
    String unitTitle,
    String subjectName,
    String unitNumber,
  ) async {
    try {
      final key = '$subjectName-$unitNumber';
      if (mounted) {
        setState(() {
          _downloadingUnits.add(key);
          _downloadProgress[key] = ValueNotifier<double>(0.0);
        });
      }

      // Get signed URL
            String url = await PdfService.getPdfUrl(unitPath);
      
      // Start download in background (don't wait for completion)
      // This allows download to continue even if user leaves the screen
      _downloadManager
          .downloadFileWithProgress(
            fileUrl: url,
            fileName: unitTitle,
            subject: subjectName,
            semester: widget.subjectName,
            branch: widget.branchId,
            unitNumber: unitNumber,
            type: 'unit_notes',
            onProgress: (progress) {
              // Update only the specific progress bar via ValueNotifier
              if (_downloadProgress.containsKey(key)) {
                _downloadProgress[key]!.value = progress;
              }
                          },
          )
          .then((downloadedFile) {
            // Handle completion - only show message if screen is still mounted
            if (mounted) {
              setState(() {
                _downloadingUnits.remove(key);
                _downloadProgress[key]?.dispose();
                _downloadProgress.remove(key);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Download successful'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

                          } else {
              // Download completed but screen unmounted, just log it
                          }
          })
          .catchError((e) {
            // Handle errors - only show if screen is still mounted
            if (mounted) {
              setState(() {
                _downloadingUnits.remove(key);
                _downloadProgress[key]?.dispose();
                _downloadProgress.remove(key);
              });

              final errorStr = e.toString().replaceAll('Exception: ', '');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Download failed: $errorStr'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
    } catch (e) {
      final key = '$subjectName-$unitNumber';
      if (mounted) {
        setState(() {
          _downloadingUnits.remove(key);
          _downloadProgress[key]?.dispose();
          _downloadProgress.remove(key);
        });

        final errorStr = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to start download: $errorStr'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _getViewerScreen(String filePath, String fileName) {
    // Since all uploads are strictly PDFs, always return the PDFViewerScreen directly.
    // This bypasses any file extension checking and prevents failures on files with missing extensions.
    return PDFViewerScreen.file(
      filePath: filePath,
      fileName: fileName,
      subject: widget.subjectName,
    );
  }

  Future<void> _openDownloadedFile(
    BuildContext context,
    String subjectName,
    String unitNumber,
  ) async {
    try {
      final downloadedFile = _downloadsService.getDownloadedFile(
        subjectName,
        unitNumber,
      );

      if (downloadedFile != null) {
        // Add to history with subject
        await _historyService.addToHistory(
          id: downloadedFile.id,
          name: downloadedFile.name,
          type: 'note',
          filePath: downloadedFile.filePath,
          subject: downloadedFile.subject,
        );

        // Open offline file using file factory method
        if (mounted) {
          // Verify file exists
          final file = File(downloadedFile.filePath);
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
                downloadedFile.filePath,
                downloadedFile.name,
              ),
            ),
          );
        }
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

  Future<void> _openPdfUnit(String path, String title) async {
    try {
      if (!mounted) return;

      
      // Show small loading indicator overlay
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          builder: (context) => Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
          ),
        );
      }

      // 🔥 Call Cloudflare Worker to get signed URL
      String url = await PdfService.getPdfUrl(path);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // 🔥 NAVIGATE TO PDF VIEWER directly with signed URL
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen.network(
              url: url,
              fileName: title,
              subject: widget.subjectName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        final errorStr = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to open PDF: $errorStr'),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
