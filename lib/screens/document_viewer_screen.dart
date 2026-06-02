import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/file_type_service.dart';
import 'pdf_viewer_screen.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String? url;
  final bool isNetworkFile;
  final DocumentType documentType;
  final String subject;

  const DocumentViewerScreen({
    super.key,
    this.filePath = '',
    required this.fileName,
    this.url,
    this.isNetworkFile = false,
    required this.documentType,
    this.subject = '',
  });

  factory DocumentViewerScreen.network({
    required String url,
    required String fileName,
    String subject = '',
  }) {
    // Try to detect type from URL first (which has the actual filename with extension)
    // If that fails, try the provided fileName
    var docType = FileTypeService.detectType(url);
    if (docType == DocumentType.unknown) {
      docType = FileTypeService.detectType(fileName);
    }
    // App is now PDF-only, so default to PDF if still unknown
    if (docType == DocumentType.unknown) {
      docType = DocumentType.pdf;
    }
    
    return DocumentViewerScreen(
      fileName: fileName,
      url: url,
      isNetworkFile: true,
      documentType: docType,
      subject: subject,
    );
  }

  factory DocumentViewerScreen.file({
    required String filePath,
    required String fileName,
    String subject = '',
  }) {
    // Try to detect type from filePath first, then fallback to fileName
    var docType = FileTypeService.detectType(filePath);
    if (docType == DocumentType.unknown) {
      docType = FileTypeService.detectType(fileName);
    }
    // App is now PDF-only, so default to PDF if still unknown
    // This is especially important for downloaded files where the extension might have been stripped
    if (docType == DocumentType.unknown) {
      docType = DocumentType.pdf;
    }
    
        return DocumentViewerScreen(
      filePath: filePath,
      fileName: fileName,
      isNetworkFile: false,
      documentType: docType,
      subject: subject,
    );
  }

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Defer navigation until after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDocument();
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _initializeDocument() async {
    try {
      // Route to appropriate viewer based on file type
      if (widget.documentType == DocumentType.pdf) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => widget.isNetworkFile
                ? PDFViewerScreen.network(
                    url: widget.url!,
                    fileName: widget.fileName,
                    subject: widget.subject,
                  )
                : PDFViewerScreen.file(
                    filePath: widget.filePath,
                    fileName: widget.fileName,
                    subject: widget.subject,
                  ),
          ),
        );
        return;
      }

      throw Exception(
        'Unsupported file type: ${widget.documentType.displayName}. Please use PDF instead.',
      );
    } catch (e) {
            if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: const Color(0xFF6B7280),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Opening ${widget.documentType.displayName}...',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
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
                      'Failed to Open Document',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error ?? 'Unknown error occurred',
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
                  ],
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
