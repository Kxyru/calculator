import 'package:flutter_test/flutter_test.dart';
import 'package:offline_calculator/features/calculator/services/calculation_engine.dart';

void main() {
  final engine = CalculationEngine();

  double evaluate(String expression) => engine.evaluate(expression).value;

  group('CalculationEngine', () {
    test('evaluates basic operations and decimal precision', () {
      expect(evaluate('2+3'), 5);
      expect(evaluate('9-12'), -3);
      expect(evaluate('3*4'), 12);
      expect(evaluate('8/2'), 4);
      expect(evaluate('0.1+0.2'), closeTo(0.3, 1e-12));
    });

    test('respects precedence and parentheses', () {
      expect(evaluate('5+3*2'), 11);
      expect(evaluate('(5+3)*2'), 16);
    });

    test('supports unary signs and percent conventions', () {
      expect(evaluate('-5*3'), -15);
      expect(evaluate('50+10%'), 55);
      expect(evaluate('200*10%'), 20);
      expect(evaluate('100-25%'), 75);
      expect(evaluate('10%'), 0.1);
    });

    test('reports safe recoverable errors', () {
      for (final expression in ['', '10/0', '2+', '2..3', '(1+2', '1+@']) {
        expect(
          () => evaluate(expression),
          throwsA(isA<CalculationException>()),
        );
      }
    });

    test('bounds expression size and rejects non-finite results', () {
      expect(
        () => evaluate(List.filled(260, '1').join('+')),
        throwsA(isA<CalculationException>()),
      );
      expect(() => evaluate('1e309'), throwsA(isA<CalculationException>()));
      expect(() => evaluate('9' * 400), throwsA(isA<CalculationException>()));
    });

    test('exposes final operation for repeated equals', () {
      final result = engine.evaluate('2+3*4');
      expect(result.value, 14);
      expect(result.repeatedOperator, '+');
      expect(result.repeatedOperand, 12);
    });
  });
}
