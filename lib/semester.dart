import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/app_scaffold.dart';
import 'subjects.dart';

class SemesterScreen extends StatefulWidget {
  final String branch;
  final String branchPrefix;
  final String regulation;

  const SemesterScreen({
    super.key,
    required this.branch,
    required this.branchPrefix,
    required this.regulation,
  });

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen> {
  final List<String> semesters = const [
    "1-1",
    "1-2",
    "2-1",
    "2-2",
    "3-1",
    "3-2",
    "4-1",
  ];

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
            /// Header with Gradient
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
                    "Select Semester",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Branch: ${widget.branch}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// Semester Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: semesters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
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
                      // Navigate to subjects selection
                      _navigateToSubjects(semesters[index]);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          "Semester ${semesters[index]}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Future<void> _navigateToSubjects(String semester) async {
    try {
      // Combine branch prefix with semester to create document ID
      // e.g., "aid" + "1-1" = "aid_1-1"
      String branchId = "${widget.branchPrefix}_$semester";

      // Use branchId directly to access the branch document
      final branchDoc = await FirebaseFirestore.instance
          .collection('branches')
          .doc(branchId)
          .get();

      if (!mounted) return;

      if (branchDoc.exists) {
        final branchName = branchDoc['name'] ?? widget.branch;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectsScreen(
              branchId: branchId,
              branchName: branchName,
              semester: semester,
            ),
          ),
        );
      } else {
        // Fallback if branch not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Branch "${widget.branch}" semester "$semester" not found in database',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading subjects: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
