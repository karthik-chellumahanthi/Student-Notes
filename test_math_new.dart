import 'package:math_expressions/math_expressions.dart';

void main() {
  GrammarParser p = GrammarParser();
  Expression exp = p.parse("5+5");
  ContextModel cm = ContextModel();
  
  try {
    double result = exp.evaluate(EvaluationType.REAL, cm);
    print("Old evaluate: $result");
  } catch (e) {
    print("Error: $e");
  }
}
