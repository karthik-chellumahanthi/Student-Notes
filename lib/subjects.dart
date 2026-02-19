import 'package:flutter/material.dart';
import 'widgets/app_scaffold.dart';

class SubjectsScreen extends StatefulWidget {
  final String branch;
  final String semester;
  final String regulation;

  const SubjectsScreen({
    super.key,
    required this.branch,
    required this.semester,
    required this.regulation,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  int _currentIndex = 0;

  // Subjects data structure: branch -> semester -> list of subjects
  final Map<String, Map<String, List<String>>> subjectsData = {
    "CSE(AIDS)": {
      "1-1": ["LA&C", "C - Language", "PHYSICS", "BEEE", "EG"],
      "1-2": ["DE&VC", "Data Structures", "English", "BC&ME", "Chemistry"],
      "2-1": ["UHV", "DM&GT", "ADS", "JAVA", "DBMS"],
      "2-2": ["OS", "SE", "OT", "SMDS", "IDS"],
      "3-1": ["EDVC", "CN", "IOT", "CO&A", "AI"],
      "3-2": ["COMING_SOON"],
      "4-1": ["COMING_SOON"],
      "4-2": ["COMING_SOON"],
    },
  };

  List<String> get _subjects {
    return subjectsData[widget.branch]?[widget.semester] ?? [];
  }

  bool _isComingSoon(String semester) {
    return semester == "3-2" || semester == "4-1" || semester == "4-2";
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
            /// Header with Gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Subject",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Branch: ${widget.branch} | Semester: ${widget.semester}",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Display subjects or coming soon
            if (_isComingSoon(widget.semester))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Coming Soon",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Subjects for this semester will be available soon",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else if (_subjects.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No subjects available for this branch and semester",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final colors = [
                    const Color(0xFF667EEA),
                    const Color(0xFFF5576C),
                    const Color(0xFF00F2FE),
                    const Color(0xFFFECE73),
                  ];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors[index % colors.length],
                          colors[(index + 1) % colors.length],
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Handle subject selection
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Selected: ${_subjects[index]}"),
                              backgroundColor: colors[index % colors.length],
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _subjects[index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
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
