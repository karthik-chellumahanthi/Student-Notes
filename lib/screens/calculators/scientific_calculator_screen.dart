import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import '../../services/calculator_history_service.dart';
import 'calculator_history_screen.dart';

class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  State<ScientificCalculatorScreen> createState() =>
      _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState
    extends State<ScientificCalculatorScreen> {
  String _equation = "";
  String _result = "0";

  final List<String> _buttons = [
    'log',
    'ln',
    'e',
    '!',
    'sin',
    'cos',
    'tan',
    '^',
    '(',
    ')',
    'sqrt',
    '%',
    '7',
    '8',
    '9',
    'AC',
    '4',
    '5',
    '6',
    'DEL',
    '1',
    '2',
    '3',
    '×',
    '0',
    '.',
    'π',
    '÷',
    '00',
    '+',
    '-',
    '=',
  ];

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _equation = "";
        _result = "0";
      } else if (buttonText == "DEL") {
        if (_equation.isNotEmpty) {
          _equation = _equation.substring(0, _equation.length - 1);
        }
        if (_equation.isEmpty) {
          _result = "0";
        }
      } else if (buttonText == "=") {
        _calculate();
      } else {
        if (["sin", "cos", "tan", "ln", "log", "sqrt"].contains(buttonText)) {
          _equation += "$buttonText(";
        } else {
          _equation += buttonText;
        }
      }
    });
  }

  void _calculate() {
    if (_equation.isEmpty) return;

    String expressionToParse = _equation;
    expressionToParse = expressionToParse.replaceAll('×', '*');
    expressionToParse = expressionToParse.replaceAll('÷', '/');
    expressionToParse = expressionToParse.replaceAll('π', '3.1415926535897932');
    expressionToParse = expressionToParse.replaceAll('e', '2.718281828459045');
    expressionToParse = expressionToParse.replaceAll('%', '/100');
    expressionToParse = expressionToParse.replaceAll('log(', 'log(10,');

    try {
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(expressionToParse);
      ContextModel cm = ContextModel();
      RealEvaluator evaluator = RealEvaluator(cm);

      num eval = evaluator.evaluate(exp);

      String res = eval.toString();
      if (res.endsWith(".0")) {
        res = res.substring(0, res.length - 2);
      }

      setState(() {
        _result = res;
      });

      CalculatorHistoryService.addRecord(
        CalculationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Scientific',
          details: _equation,
          result: res,
          date: DateTime.now(),
        ),
      );
    } catch (e) {
      setState(() {
        _result = "Syntax Error";
      });
    }
  }

  Color _getButtonColor(String buttonText) {
    if (buttonText == "AC" || buttonText == "DEL") {
      return Colors.red[400]!;
    } else if (buttonText == "=") {
      return Colors.blue[600]!;
    } else if ([
      "sin",
      "cos",
      "tan",
      "ln",
      "log",
      "sqrt",
      "^",
      "(",
      ")",
      "%",
      "π",
      "e",
      "!",
    ].contains(buttonText)) {
      return Colors.grey[800]!;
    } else if (["+", "-", "×", "÷"].contains(buttonText)) {
      return Colors.orange[600]!;
    }
    return Colors.grey[700]!;
  }

  Widget _buildButton(String buttonText) {
    return Container(
      margin: const EdgeInsets.all(6),
      child: Material(
        color: _getButtonColor(buttonText),
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: () => _buttonPressed(buttonText),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark theme like Casio
      appBar: AppBar(
        title: const Text('Scientific Calculator'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalculatorHistoryScreen(),
                ),
              );
            },
            tooltip: 'History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Display Screen
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E5EC), // Casio screen color
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[600]!, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _equation,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.black54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Casio FX 991EX Branding mock
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CASIO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'fx-991EX PLUS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Buttons Grid
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(8, (rowIndex) {
                  return Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(4, (colIndex) {
                        int index = rowIndex * 4 + colIndex;
                        return Expanded(child: _buildButton(_buttons[index]));
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
