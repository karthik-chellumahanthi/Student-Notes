import 'package:flutter/material.dart';
import 'widgets/app_scaffold.dart';

class QuestionPapersScreen extends StatefulWidget {
  final String regulation;
  final String branch;

  const QuestionPapersScreen({
    super.key,
    required this.regulation,
    required this.branch,
  });

  @override
  State<QuestionPapersScreen> createState() => _QuestionPapersScreenState();
}

class _QuestionPapersScreenState extends State<QuestionPapersScreen> {
  final List<String> semesters = const [
    "1-1",
    "1-2",
    "2-1",
    "2-2",
    "3-1",
    "3-2",
    "4-1",
  ];

  // Subjects data for question papers - same as notes section
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
        "1-1": ["LA&C", "C - Language", "Physics", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "JAVA", "DBMS"],
        "2-2": ["OS", "SE", "OT", "SMDS", "IDS"],
        "3-1": ["EDVC", "CN", "IOT", "CO&A", "AI"],
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
        "1-1": ["LA&C", "C - Language", "Physics", "BEEE", "EG"],
        "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
        "2-1": ["UHV", "DM&GT", "ADS", "JAVA", "AI"],
        "2-2": ["Probability & Statistics", "DBMS", "OT", "ML", "DLCO"],
        "3-1": ["EDVC", "OS", "CN", "IOT", "Deep Learning"],
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
                    "Previous Question Papers",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Regulation: ${widget.regulation} | Branch: ${widget.branch}",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// Semesters Grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Select Semester",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: semesters.length,
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
                      // Get subjects for selected semester
                      widget.regulation;
                      widget.branch;
                      semesters[index];
                      final subjectsForSemester =
                          regulationData[widget.regulation]?[widget
                              .branch]?[semesters[index]] ??
                          [];

                      // Show dialog with subjects
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              "${widget.regulation} - Semester ${semesters[index]}",
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: subjectsForSemester.map((subject) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8E8E8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      "Semester ${semesters[index]}",
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
