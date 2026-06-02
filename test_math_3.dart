import 'package:math_expressions/math_expressions.dart';

void main() {
  GrammarParser p = GrammarParser();
  p.parse("x+5");
  ContextModel cm = ContextModel();
  cm.bindVariable(Variable('x'), Number(5));

  // Try passing ContextModel to evaluate
  // Or trying to evaluate without context model?
  // Let's print the evaluate method signature via analyzer or just try it:

  // Try RealEvaluator(cm)? No, wait.
  // Maybe evaluate(EvaluationType.REAL, cm) still works but let's see what RealEvaluator is.
  var evaluator = RealEvaluator();
  print(evaluator.runtimeType);
}
