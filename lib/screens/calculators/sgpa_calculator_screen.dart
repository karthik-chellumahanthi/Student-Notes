import 'package:flutter/material.dart';
import '../../services/calculator_history_service.dart';

class SubjectEntry {
  double credits;
  int gradePoints;
  SubjectEntry({this.credits = 3.0, this.gradePoints = 10});
}

class SgpaCalculatorScreen extends StatefulWidget {
  const SgpaCalculatorScreen({super.key});

  @override
  State<SgpaCalculatorScreen> createState() => _SgpaCalculatorScreenState();
}

class _SgpaCalculatorScreenState extends State<SgpaCalculatorScreen> {
  final List<SubjectEntry> _subjects = List.generate(
    6,
    (index) => SubjectEntry(),
  );
  String? _result;

  final Map<String, int> _grades = {
    'O (10)': 10,
    'A+ (9)': 9,
    'A (8)': 8,
    'B+ (7)': 7,
    'B (6)': 6,
    'C (5)': 5,
    'D (4)': 4,
    'F/Abs (0)': 0,
  };

  void _addSubject() {
    setState(() {
      _subjects.add(SubjectEntry());
    });
  }

  void _removeSubject(int index) {
    if (_subjects.length > 1) {
      setState(() {
        _subjects.removeAt(index);
      });
    }
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    double totalCredits = 0;
    double totalPoints = 0;

    for (var subject in _subjects) {
      totalCredits += subject.credits;
      totalPoints += (subject.credits * subject.gradePoints);
    }

    if (totalCredits == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total credits cannot be zero')),
      );
      return;
    }

    double sgpa = totalPoints / totalCredits;

    setState(() {
      _result = sgpa.toStringAsFixed(2);
    });

    CalculatorHistoryService.addRecord(
      CalculationRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'SGPA',
        details:
            '${_subjects.length} Subjects, Total Credits: ${totalCredits.toStringAsFixed(1)}',
        result: _result!,
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SGPA Calculator'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSubject,
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green[300]
                                    : Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<double>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Credits',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _subjects[index].credits,
                            items: [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c.toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _subjects[index].credits = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Grade',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _subjects[index].gradePoints,
                            items: _grades.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.value,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(
                                  () => _subjects[index].gradePoints = val,
                                );
                              }
                            },
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeSubject(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_result != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Your SGPA: ',
                          style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey),
                        ),
                        Text(
                          _result!,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.green[300]
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Calculate SGPA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
