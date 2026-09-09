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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefix = "${widget.branchPrefix.toLowerCase()}_";

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
                color: isDark ? Colors.grey[800] : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Semester",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Branch: ${widget.branch}",
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// Dynamic Semester Grid from Firestore
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('branches')
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.menu_book, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            "No Semesters Found",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter branch documents matching prefix (e.g. "csm_1-1", "csm_1-2")
                List<String> availableSemesters = [];
                for (var doc in snapshot.data!.docs) {
                  final docId = doc.id.toLowerCase();
                  if (docId.startsWith(prefix)) {
                    final sem = doc.id.substring(prefix.length);
                    if (sem.isNotEmpty && !availableSemesters.contains(sem)) {
                      availableSemesters.add(sem);
                    }
                  }
                }

                // Sort semesters e.g. "1-1", "1-2", "2-1", etc.
                availableSemesters.sort((a, b) => a.compareTo(b));

                if (availableSemesters.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.menu_book, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            "No Semesters Found",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: availableSemesters.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final sem = availableSemesters[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE8E8E8),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _navigateToSubjects(sem);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              "Semester $sem",
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
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _navigateToSubjects(String semester) {
    // Combine branch prefix with semester to create document ID
    // e.g., "aid" + "1-1" = "aid_1-1"
    String branchId = "${widget.branchPrefix}_$semester";

    // Navigate instantly! 
    // If the branch doesn't exist, SubjectsScreen will naturally show "No Subjects Found"
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectsScreen(
          branchId: branchId,
          branchName: widget.branch,
          semester: semester,
        ),
      ),
    );
  }
}
