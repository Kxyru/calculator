import 'package:flutter_test/flutter_test.dart';
import 'package:offline_calculator/features/calculator/controllers/calculator_controller.dart';
import 'package:offline_calculator/features/history/services/history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CalculatorController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    controller = CalculatorController(
      historyRepository: HistoryRepository(preferences),
    );
    await controller.loadHistory();
  });

  test('handles chained calculations and continuing from a result', () async {
    controller.inputDigit('5');
    controller.inputOperator('+');
    controller.inputDigit('3');
    controller.inputOperator('*');
    controller.inputDigit('2');
    await controller.calculate();
    expect(controller.resultValue, 11);

    controller.inputOperator('+');
    controller.inputDigit('4');
    await controller.calculate();
    expect(controller.resultValue, 15);
  });

  test('repeats equals and avoids duplicate history events', () async {
    controller.inputDigit('2');
    controller.inputOperator('+');
    controller.inputDigit('3');
    await controller.calculate();
    expect(controller.resultValue, 5);
    await controller.calculate();
    expect(controller.resultValue, 8);
    expect(controller.history, hasLength(2));
  });

  test('supports decimal, clear, backspace, and error recovery', () async {
    controller.inputDigit('1');
    controller.inputDecimal();
    controller.inputDecimal();
    controller.inputDigit('5');
    expect(controller.expression, '1.5');
    controller.backspace();
    expect(controller.expression, '1.');
    controller.clear();
    await controller.calculate();
    expect(controller.errorMessage, isNotNull);
    controller.inputDigit('7');
    expect(controller.errorMessage, isNull);
    expect(controller.expression, '7');
  });

  test('supports unary minus and percent calculation', () async {
    controller.inputDigit('5');
    controller.inputOperator('+');
    controller.inputDigit('1');
    controller.inputDigit('0');
    controller.inputPercent();
    await controller.calculate();
    expect(controller.resultValue, 5.5);
  });

  test('accepts valid grouped paste and rejects malformed paste', () async {
    expect(await controller.pasteExpression('1,234+2'), isTrue);
    expect(controller.expression, '1234+2');
    expect(controller.resultText, '1,236');
    expect(await controller.pasteExpression('1,2+3'), isFalse);
    expect(controller.expression, '1234+2');
  });
}
