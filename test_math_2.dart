import 'package:math_expressions/math_expressions.dart';

void main() {
  GrammarParser p = GrammarParser();
  p.parse("5+5");

  // or maybe the evaluator has evaluate?
  // evaluator.evaluate(exp) doesn't take cm? Let's check constructor.
  // RealEvaluator evaluator = RealEvaluator();
  // print(evaluator.evaluate(exp));
}
