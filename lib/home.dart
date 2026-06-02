import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_scaffold.dart';
import 'semester.dart';
import 'question_papers_branch.dart';
import 'profile.dart';
import 'services/auth_service.dart';
import 'services/downloads_service.dart';
import 'screens/document_viewer_screen.dart';
import 'screens/more_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final AuthService? authService;

  const HomeScreen({super.key, this.initialTabIndex = 0, this.authService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  String? _selectedNotesRegulation;
  String? _selectedQuestionsRegulation;
  late AuthService _authService;
  late DownloadsService _downloadsService;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _downloadsService = DownloadsService();
    _loadDownloads();
    _loadSavedRegulations();
    _currentIndex = widget.initialTabIndex;
    _checkInitialConnectivity();
    _setupConnectivityListener();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Small delay to ensure the screen is fully rendered before showing dialog
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (!mounted) return;
    if (await UpdateService.needsForceUpdate()) {
      UpdateDialog.show(context, isForceUpdate: true);
    } else if (await UpdateService.hasOptionalUpdate()) {
      UpdateDialog.show(context, isForceUpdate: false);
    }
  }

  Future<void> _loadSavedRegulations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotesRegulation = prefs.getString('selectedNotesRegulation');
      final savedQuestionsRegulation = prefs.getString(
        'selectedQuestionsRegulation',
      );
      if (mounted) {
        setState(() {
          if (savedNotesRegulation != null) {
            _selectedNotesRegulation = savedNotesRegulation;
          }
          if (savedQuestionsRegulation != null) {
            _selectedQuestionsRegulation = savedQuestionsRegulation;
          }
        });
      }
    } catch (e) {
      // Error loading regulations, silently fail
    }
  }

  Future<void> _saveNotesRegulation(String? regulation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (regulation != null) {
        await prefs.setString('selectedNotesRegulation', regulation);
      } else {
        await prefs.remove('selectedNotesRegulation');
      }
    } catch (e) {
      // Error saving regulation, silently fail
    }
  }

  Future<void> _saveQuestionsRegulation(String? regulation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (regulation != null) {
        await prefs.setString('selectedQuestionsRegulation', regulation);
      } else {
        await prefs.remove('selectedQuestionsRegulation');
      }
    } catch (e) {
      // Error saving regulation, silently fail
    }
  }

  Future<void> _loadDownloads() async {
    try {
      // Initialize the service first to set up SharedPreferences
      await _downloadsService.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Error loading downloads, silently fail
    }
  }

  Future<void> _checkInitialConnectivity() async {
    final isOnline = await _authService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
      // If offline and user is logged in, redirect to downloads
      if (!isOnline) {
        _goToDownloads();
      }
    }
  }

  void _setupConnectivityListener() {
    _authService.getConnectivityStream().listen((results) {
      final isOnline =
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        // If went offline, redirect to downloads
        if (!isOnline && _currentIndex != 1) {
          _goToDownloads();
        }
      }
    });
  }

  void _goToDownloads() {
    setState(() {
      _currentIndex = 1;
    });
  }

  // Regulations with their branches, semesters, and subjects
  final Map<String, Map<String, Map<String, List<String>>>> regulationData = {
    "R23": {
      "CSE": {
        "1-1": ["LA&C", "C - Language", "BC&ME", "English", "Chemistry"],
        "1-2": ["DE&VC", "Data Structures", "BEEE", "Physics", "EG"],
        "2-1": ["UHV", "DM&GT", "ADS", "JAVA", "DLCO"],
        "2-2": [
          "Probability & Statistics",
          "OS",
          "DBMS",
          "SE",
          "Managerial Economics & Financial Analysis",
        ],
        "3-1": [
          "Data Warehouse & Data Mining",
          "CN",
          "Formal Languages & Automata Theory",
          "AI",
          "Renewable Energy Sources",
        ],
        "3-2": [
          "Compiler Design",
          "Cloud Computing",
          "Cryptography & Network Security",
          "DevOps",
          "Microprocessors & Microcontrollers",
        ],
        "4-1": ["COMING_SOON"],
      },
      "AIDS": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "ML Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "DL Fundamentals", "IDS"],
        "3-1": ["EDVC", "CN", "NLP", "CV", "AI"],
        "3-2": [
          "BDA",
          "NoSQL",
          "Cloud Computing",
          "Disaster Management",
          "ML",
          "Data Visualization",
        ],
        "4-1": ["COMING_SOON"],
      },
      "CAI": {
        "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "Cloud Basics", "DBMS"],
        "2-2": ["OS", "SE", "OT", "Cloud Security", "IDS"],
        "3-1": ["EDVC", "CN", "Cloud Architecture", "DevOps", "AI"],
        "3-2": [
          "Cloud Computing",
          "Data Visualization",
          "Disaster Management",
          "Operating System",
          "Data Visualization",
          "Software Testing Methodology",
        ],
        "4-1": ["COMING_SOON"],
      },
    },
  };

  // Regulations and their corresponding branches
  final Map<String, List<String>> regulationBranches = {
    "R23": ["CSE", "AIDS", "CAI"],
  };

  List<String> get _filteredBranches {
    if (_selectedNotesRegulation == null) {
      return [];
    }
    return regulationBranches[_selectedNotesRegulation] ?? [];
  }

  // Map branch display names to Firestore document ID prefixes
  String _getBranchIdPrefix(String branchName) {
    const Map<String, String> branchPrefixMap = {
      'CSE': 'cse',
      'AIDS': 'aid',
      'CAI': 'cai',
    };
    return branchPrefixMap[branchName] ?? branchName.toLowerCase();
  }

  void _showNotesRegulationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "📚 Select Regulation",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    "Choose your academic regulation to access study notes for your branch and semester",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...regulationBranches.keys.map((regulation) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF9F7AEA),
                        width: 2,
                      ),
                      color: const Color(0xFFFAF5FF),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedNotesRegulation = regulation;
                          });
                          _saveNotesRegulation(regulation);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCCAFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  regulation,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF5B21B6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "Regulation $regulation",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                                color: const Color(0xFF7C3AED),
                                weight: 700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showQuestionPapersRegulationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "📄 Select Regulation",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    "Choose your academic regulation to view previous question papers",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...regulationBranches.keys.map((regulation) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF14B8A6),
                        width: 2,
                      ),
                      color: const Color(0xFFF0FDFA),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedQuestionsRegulation = regulation;
                          });
                          _saveQuestionsRegulation(regulation);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionPapersBranchScreen(
                                regulation: regulation,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  regulation,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "Regulation $regulation",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                                color: const Color(0xFF0D9488),
                                weight: 700,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: _currentIndex,
      onBottomNavTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      onDrawerNavigate: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _getBodyForIndex(_currentIndex),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Welcome Section with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "👋 Welcome, Buddy",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Access study materials and resources",
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// NOTES SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "📚 Notes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Step 1",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Choose your academic regulation to access study notes for your branch and semester",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showNotesRegulationDialog();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCCAFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF5B21B6),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedNotesRegulation != null
                                      ? _selectedNotesRegulation!
                                      : "Select Regulation",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _selectedNotesRegulation != null
                                        ? const Color(0xFF5B21B6)
                                        : const Color(0xFF7C3AED),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedNotesRegulation != null
                                      ? "Tap to change regulation"
                                      : "Tap to choose your regulation",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF5B21B6),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_selectedNotesRegulation != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "🎓 Branch Selection",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Step 2",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Select your branch under Regulation $_selectedNotesRegulation",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredBranches.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.5,
                        ),
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6EE7B7),
                            width: 1.5,
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD1FAE5),
                            foregroundColor: const Color(0xFF065F46),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SemesterScreen(
                                  branch: _filteredBranches[index],
                                  branchPrefix: _getBranchIdPrefix(
                                    _filteredBranches[index],
                                  ),
                                  regulation: _selectedNotesRegulation!,
                                ),
                              ),
                            ).then((returnedIndex) {
                              if (returnedIndex != null &&
                                  returnedIndex is int) {
                                setState(() {
                                  _currentIndex = returnedIndex;
                                });
                              }
                            });
                          },
                          child: Text(
                            _filteredBranches[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  if (_filteredBranches.isNotEmpty)
                    Text(
                      "📌 We are adding more branches very soon",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          /// PREVIOUS QUESTION PAPERS SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCFBF1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "📄 Previous Question Papers",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Step 1",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Access previous years' question papers to prepare for your exams",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showQuestionPapersRegulationDialog();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF99F6E4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_outlined,
                              color: Color(0xFF0D9488),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedQuestionsRegulation != null
                                      ? _selectedQuestionsRegulation!
                                      : "Select Regulation",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _selectedQuestionsRegulation != null
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFF14B8A6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedQuestionsRegulation != null
                                      ? "Tap to change regulation"
                                      : "Select regulation and semester to view papers",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF0D9488),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDownloadsScreen() {
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
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (download.subject.isNotEmpty)
                                          Text(
                                            download.subject,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    "Size: ${DownloadsService.formatFileSize(download.fileSize)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(download.downloadedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _openPDFViewer(download);
                                    },
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      "Open",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B7280),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      // Show confirmation dialog before deleting
                                      final confirmed =
                                          await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Delete Download?',
                                                ),
                                                content: Text(
                                                  'Are you sure you want to delete "${download.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        dialogContext,
                                                        false,
                                                      );
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        dialogContext,
                                                        true,
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ) ??
                                          false;

                                      if (confirmed && mounted) {
                                        try {
                                          await _downloadsService
                                              .deleteDownload(download.id);
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "File deleted successfully",
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Error deleting file: $e",
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text(
                                      "Delete",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
        if (!_isOnline)
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
    if (displayName.toLowerCase().endsWith('.docx') ||
        displayName.toLowerCase().endsWith('.pptx')) {
      displayName = displayName.substring(0, displayName.length - 5);
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
