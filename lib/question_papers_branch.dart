import 'package:flutter/material.dart';
import 'widgets/app_scaffold.dart';
import 'question_papers.dart';

class QuestionPapersBranchScreen extends StatefulWidget {
  final String regulation;

  const QuestionPapersBranchScreen({super.key, required this.regulation});

  @override
  State<QuestionPapersBranchScreen> createState() =>
      _QuestionPapersBranchScreenState();
}

class _QuestionPapersBranchScreenState
    extends State<QuestionPapersBranchScreen> {
  // Regulation to branches mapping
  final Map<String, List<String>> regulationBranches = {
    "R23": ["CSE", "AIDS", "CAI"],
  };

  List<String> get _filteredBranches {
    return regulationBranches[widget.regulation] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      onBottomNavTap: (index) {
        // Pop back to home with the selected index
        Navigator.of(context).pop(index);
      },
      showDrawer: false,
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Branch",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Regulation: ${widget.regulation}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// Branches Grid
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
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8E8E8),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionPapersScreen(
                            regulation: widget.regulation,
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

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
