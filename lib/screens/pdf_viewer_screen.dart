import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import '../services/screen_security_service.dart';
import '../services/pdf_cache_service.dart';
import '../services/history_service.dart';
import '../services/encryption_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String? url;
  final bool isNetworkPdf;
  final String subject;

  const PDFViewerScreen({
    super.key,
    this.filePath = '',
    required this.fileName,
    this.url,
    this.isNetworkPdf = false,
    this.subject = '',
  });

  factory PDFViewerScreen.network({
    required String url,
    required String fileName,
    String subject = '',
  }) {
    return PDFViewerScreen(
      fileName: fileName,
      url: url,
      isNetworkPdf: true,
      subject: subject,
    );
  }

  factory PDFViewerScreen.file({
    required String filePath,
    required String fileName,
    String subject = '',
  }) {
    return PDFViewerScreen(
      filePath: filePath,
      fileName: fileName,
      isNetworkPdf: false,
      subject: subject,
    );
  }

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PdfControllerPinch? _pdfController;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  final ValueNotifier<double?> _downloadProgress = ValueNotifier(null);
  String? _error;
  late HistoryService _historyService;
  late EncryptionService _encryptionService;
  String? _tempDecryptedFilePath; // Store temp file path for cleanup

  @override
  void initState() {
    super.initState();
    _initializeEncryptionAndLoad();
    // Enable secure mode to prevent screenshots
    ScreenSecurityService.enableSecureMode();

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _initializeEncryptionAndLoad() async {
    _encryptionService = EncryptionService();
    await _encryptionService.initialize();

    // Handle encrypted files
    String filePath = widget.filePath;
    if (_encryptionService.isEncrypted(filePath)) {
      try {
        debugPrint('🔓 Decrypting file: $filePath');
        _tempDecryptedFilePath = await _encryptionService.decryptFile(filePath);
        filePath = _tempDecryptedFilePath!;
        debugPrint('✅ File decrypted to: $filePath');
      } catch (e) {
        debugPrint('❌ Error decrypting file: $e');
        if (mounted) {
          String errorMsg = 'Failed to decrypt file: ${e.toString()}';

          // Provide helpful message if decryption key was lost
          if (e.toString().contains('app update') ||
              e.toString().contains('Key mismatch')) {
            errorMsg =
                'File encryption key was lost (possibly due to app update).\n\n'
                'Please re-download this file to access it again.';
          }

          setState(() {
            _error = errorMsg;
            _isLoading = false;
          });
        }
        return;
      }
    }

    _historyService = await HistoryService.getInstance();
    // Add to history
    await _historyService.addToHistory(
      id: 'pdf_${widget.fileName}',
      name: widget.fileName,
      type: 'note',
      filePath: widget.isNetworkPdf ? (widget.url ?? '') : widget.filePath,
      subject: widget.subject,
    );
    _loadPDF(filePath);
  }

  @override
  void dispose() {
    // Disable secure mode when leaving the PDF viewer
    ScreenSecurityService.disableSecureMode();

    // Clean up temporary decrypted file
    if (_tempDecryptedFilePath != null) {
      _encryptionService.deleteTempFile(_tempDecryptedFilePath!);
    }

    _pdfController?.dispose();
    _downloadProgress.dispose();
    // Reset orientation to default
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Retry loading PDF for the "Try Again" button
  Future<void> _retryLoadPDF() async {
    String filePath = widget.filePath;
    if (widget.isNetworkPdf) {
      // For network files, we can't retry with the stored file path
      // Just use the widget values
      _loadPDF('');
    } else {
      // For local files, use stored path
      _loadPDF(filePath);
    }
  }

  Future<void> _loadPDF(String filePath) async {
    try {
      late Future<PdfDocument> documentFuture;

      if (widget.isNetworkPdf && widget.url != null) {
        // Load PDF from network URL
        debugPrint('📄 Loading PDF from URL: ${widget.url}');
        documentFuture = _loadNetworkPdf(widget.url!);
      } else {
        // Load PDF from local file using pdfx
        debugPrint('📄 Loading PDF from file using pdfx: $filePath');
        final file = File(filePath);
        if (!file.existsSync()) {
          if (mounted) {
            setState(() {
              _error = 'File not found: $filePath';
              _isLoading = false;
            });
          }
          return;
        }
        documentFuture = PdfDocument.openFile(filePath);
      }

      _pdfController = PdfControllerPinch(document: documentFuture);
      final document = await documentFuture;
      if (mounted) {
        setState(() {
          _totalPages = document.pagesCount;
          _isLoading = false;
          debugPrint('✅ PDF loaded successfully. Pages: $_totalPages');
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<PdfDocument> _loadNetworkPdf(String url) async {
    debugPrint('📥 Loading PDF (with cache check)...');
    try {
      DateTime lastUpdateTime = DateTime.now();
      // Use PdfCacheService to get or download PDF
      final pdfFile = await PdfCacheService.getPdf(url, onProgress: (progress) {
        if (mounted) {
          final now = DateTime.now();
          if (now.difference(lastUpdateTime).inMilliseconds >= 1000 || progress >= 0.99) {
            lastUpdateTime = now;
            _downloadProgress.value = progress;
          }
        }
      });
      debugPrint('✅ PDF file ready: ${pdfFile.path}');
      if (mounted) {
        _downloadProgress.value = null; // Download finished
      }
      return PdfDocument.openFile(pdfFile.path);
    } catch (e) {
      debugPrint('❌ Error loading PDF: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: const Color(0xFF6B7280),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Loading PDF...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<double?>(
                    valueListenable: _downloadProgress,
                    builder: (context, progress, child) {
                      if (progress != null) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 48),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Loading... ${(progress * 100).toInt()}%',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        );
                      } else {
                        return Text(
                          'Preparing document for viewing',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Failed to Load PDF',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7280),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _retryLoadPDF();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF6B7280)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _pdfController != null
                      ? PdfViewPinch(
                          controller: _pdfController!,
                          onDocumentLoaded: (document) async {
                            setState(() {
                              _totalPages = document.pagesCount;
                            });
                          },
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                        )
                      : const Center(child: Text('Failed to load PDF')),
                ),
                // Bottom navigation
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1 && _pdfController != null
                            ? () {
                                _pdfController!.previousPage(
                                  curve: Curves.ease,
                                  duration: const Duration(milliseconds: 300),
                                );
                              }
                            : null,
                      ),
                      Text(
                        'Page $_currentPage of $_totalPages',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed:
                            _currentPage < _totalPages && _pdfController != null
                            ? () {
                                _pdfController!.nextPage(
                                  curve: Curves.ease,
                                  duration: const Duration(milliseconds: 300),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
