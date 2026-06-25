import 'package:flutter/material.dart';
import '../../services/calculator_history_service.dart';

class PercentageCalculatorScreen extends StatefulWidget {
  const PercentageCalculatorScreen({super.key});

  @override
  State<PercentageCalculatorScreen> createState() =>
      _PercentageCalculatorScreenState();
}

class _PercentageCalculatorScreenState
    extends State<PercentageCalculatorScreen> {
  final _cgpaController = TextEditingController();
  String? _result;

  void _calculate() {
    FocusScope.of(context).unfocus();
    final cgpaStr = _cgpaController.text.trim();
    if (cgpaStr.isEmpty) return;

    final cgpa = double.tryParse(cgpaStr);
    if (cgpa == null || cgpa < 0 || cgpa > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid CGPA between 0 and 10'),
        ),
      );
      return;
    }

    // JNTUK standard formula: Percentage = (CGPA - 0.75) * 10
    double percentage = (cgpa - 0.75) * 10;
    if (percentage < 0) percentage = 0;
    if (percentage > 100) percentage = 100;

    setState(() {
      _result = percentage.toStringAsFixed(2);
    });

    CalculatorHistoryService.addRecord(
      CalculationRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Percentage',
        details: 'CGPA: $cgpaStr',
        result: '$_result%',
        date: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _cgpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percentage Calculator'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.purple.withValues(alpha: 0.2)
                      : Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.purple.withValues(alpha: 0.5)
                          : Colors.purple[100]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'JNTU Formula: Percentage = (CGPA - 0.75) × 10',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.purple[200]
                            : Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Because of this official formula, a perfect 10 CGPA converts to a maximum of 92.5%.',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.purple[100]
                            : Colors.purple[400],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _cgpaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter CGPA',
                  hintText: 'e.g. 8.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.grade),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Calculate Percentage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 48),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Equivalent Percentage',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$_result%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.purple[300]
                              : Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
