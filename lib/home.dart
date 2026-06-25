import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_scaffold.dart';
import 'semester.dart';
import 'profile.dart';
import 'services/auth_service.dart';
import 'services/downloads_service.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/more_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';
import 'widgets/home_sections.dart';
import 'widgets/download_card.dart';
import 'package:provider/provider.dart';
import 'providers/home_provider.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final AuthService? authService;

  const HomeScreen({super.key, this.initialTabIndex = 0, this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AuthService _authService;
  late DownloadsService _downloadsService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _downloadsService = DownloadsService();
    _downloadsService.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _checkForUpdates();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex != 0) {
        context.read<HomeProvider>().setTabIndex(widget.initialTabIndex);
      }
    });
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (await UpdateService.needsForceUpdate()) {
      UpdateDialog.show(context, isForceUpdate: true);
    } else if (await UpdateService.hasOptionalUpdate()) {
      UpdateDialog.show(context, isForceUpdate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    return PopScope(
      canPop: provider.currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        if (provider.currentIndex != 0) {
          // If not on Home screen, switch to Home screen
          context.read<HomeProvider>().setTabIndex(0);
        }
      },
      child: AppScaffold(
        currentIndex: provider.currentIndex,
        onBottomNavTap: (index) {
          context.read<HomeProvider>().setTabIndex(index);
        },
        onDrawerNavigate: (index) {
          context.read<HomeProvider>().setTabIndex(index);
        },
        body: _getBodyForIndex(provider.currentIndex),
      ),
    );
  }

  Widget _getBodyForIndex(int index) {
    switch (index) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildDownloadsScreen();
      case 2:
        return const MoreScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeWelcomeSection(),
          SizedBox(height: 32),
          HomeNotesSection(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDownloadsScreen() {
    final provider = context.watch<HomeProvider>();
    final downloads = _downloadsService.downloads.toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

    return Column(
      children: [
        Expanded(
          child: downloads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        "Downloads",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your downloaded materials will appear here",
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Downloaded Materials",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...downloads.map((download) {
                        return DownloadCard(
                          download: download,
                          formattedDate: _formatDate(download.downloadedAt),
                          onOpen: () => _openPDFViewer(download),
                          onDelete: () async {
                            try {
                              await _downloadsService.deleteDownload(download.id);
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("File deleted successfully"),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error deleting file: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
        if (!provider.isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.orange[100],
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange[800], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You are offline. Connect to internet to proceed.",
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Open document in appropriate viewer
  void _openPDFViewer(DownloadedFile download) {
    // Format display name for legacy files that saved the path as name
    String displayName = download.name;
    if (displayName.contains('%2F')) {
      displayName = Uri.decodeComponent(displayName).split('/').last;
    }
    if (displayName.toLowerCase().endsWith('.pdf')) {
      displayName = displayName.substring(0, displayName.length - 4);
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen.file(
          filePath: download.filePath,
          fileName: displayName,
          subject: download.subject,
        ),
      ),
    );
  }
}
