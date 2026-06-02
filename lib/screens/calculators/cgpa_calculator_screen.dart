import 'package:flutter/material.dart';
import '../../services/calculator_history_service.dart';

class SemesterEntry {
  final TextEditingController sgpaController = TextEditingController();
  final TextEditingController creditsController = TextEditingController();

  void dispose() {
    sgpaController.dispose();
    creditsController.dispose();
  }
}

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen> {
  final List<SemesterEntry> _semesters = [SemesterEntry(), SemesterEntry()];
  String? _result;

  void _addSemester() {
    setState(() {
      _semesters.add(SemesterEntry());
    });
  }

  void _removeSemester(int index) {
    if (_semesters.length > 1) {
      setState(() {
        _semesters[index].dispose();
        _semesters.removeAt(index);
      });
    }
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    double totalPoints = 0;
    double totalCredits = 0;

    for (var sem in _semesters) {
      final sgpaText = sem.sgpaController.text.trim();
      final creditsText = sem.creditsController.text.trim();

      if (sgpaText.isEmpty && creditsText.isEmpty) continue; // Skip empty rows

      final sgpa = double.tryParse(sgpaText);
      final credits = double.tryParse(creditsText);

      if (sgpa == null ||
          credits == null ||
          sgpa < 0 ||
          sgpa > 10 ||
          credits <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter valid SGPA (0-10) and Credits for all filled rows',
            ),
          ),
        );
        return;
      }

      totalCredits += credits;
      totalPoints += (sgpa * credits);
    }

    if (totalCredits == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total credits cannot be zero')),
      );
      return;
    }

    double cgpa = totalPoints / totalCredits;

    setState(() {
      _result = cgpa.toStringAsFixed(2);
    });

    CalculatorHistoryService.addRecord(
      CalculationRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'CGPA',
        details:
            'Semesters: ${_semesters.length}, Total Credits: ${totalCredits.toStringAsFixed(1)}',
        result: _result!,
        date: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    for (var sem in _semesters) {
      sem.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSemester,
            tooltip: 'Add Semester',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _semesters.length,
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Sem\n${index + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _semesters[index].sgpaController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'SGPA',
                              hintText: 'e.g. 8.5',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _semesters[index].creditsController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Credits',
                              hintText: 'e.g. 21',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeSemester(index),
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
              color: Colors.white,
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
                        const Text(
                          'Your CGPA: ',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                        Text(
                          _result!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Calculate CGPA',
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
