import 'package:math_expressions/math_expressions.dart';

void main() {
  Parser p = Parser();
  try {
    Expression exp1 = p.parse("5!");
    print("5!: ${exp1.evaluate(EvaluationType.REAL, ContextModel())}");
  } catch (e) {
    print("5! error: $e");
  }
  
  try {
    Expression exp2 = p.parse("e");
    print("e: ${exp2.evaluate(EvaluationType.REAL, ContextModel())}");
  } catch (e) {
    print("e error: $e");
  }
}
