import 'package:flutter/material.dart';
import 'widgets/app_scaffold.dart';
import 'semester.dart';
import 'question_papers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedNotesRegulation;
  bool _notesRegulationFieldHighlighted = false;

  // Regulations and their corresponding branches
  final Map<String, List<String>> regulationBranches = {
    "R23": ["CSE", "CSE(AIDS)", "CSE(CAI)"],
  };

  List<String> get _filteredBranches {
    if (_selectedNotesRegulation == null) {
      return [];
    }
    return regulationBranches[_selectedNotesRegulation] ?? [];
  }

  void _showQuestionPapersRegulationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Regulation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: regulationBranches.keys.map((regulation) {
              return ListTile(
                title: Text(regulation),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QuestionPapersScreen(regulation: regulation),
                    ),
                  );
                },
              );
            }).toList(),
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Welcome Section with Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "👋 Welcome, Buddy",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Access study materials and resources",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// NOTES SECTION
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  "📚 Notes",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "Select Your Regulation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _notesRegulationFieldHighlighted
                      ? const Color(0xFFEA4B89)
                      : const Color(0xFFE0E0E0),
                  width: _notesRegulationFieldHighlighted ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _notesRegulationFieldHighlighted
                    ? const Color(0xFFEA4B89).withValues(alpha: 0.08)
                    : const Color(0xFFFAFAFA),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _notesRegulationFieldHighlighted
                        ? "⚠️ Please select a regulation"
                        : "Choose Regulation",
                    style: TextStyle(
                      color: _notesRegulationFieldHighlighted
                          ? Colors.red
                          : Colors.grey,
                      fontWeight: _notesRegulationFieldHighlighted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                value: _selectedNotesRegulation,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                items: regulationBranches.keys.map((regulation) {
                  return DropdownMenuItem(
                    value: regulation,
                    child: Text(regulation),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedNotesRegulation = value;
                    _notesRegulationFieldHighlighted = false;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            if (_selectedNotesRegulation != null) ...[
              const Text(
                "Select Your Branch",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredBranches.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  final colors = [
                    const [Color(0xFF667EEA), Color(0xFF764BA2)],
                    const [Color(0xFFF093FB), Color(0xFFF5576C)],
                    const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  ];
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors[index % colors.length],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SemesterScreen(
                              branch: _filteredBranches[index],
                            ),
                          ),
                        );
                      },
                      child: Text(
                        _filteredBranches[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              if (_filteredBranches.isNotEmpty)
                const Text(
                  "We are adding more branches very soon",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],

            const SizedBox(height: 40),

            /// PREVIOUS QUESTION PAPERS SECTION
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  "📄 Previous Question Papers",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5576C),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showQuestionPapersRegulationDialog();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu_book_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Browse Question Papers",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Select regulation and semester",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
