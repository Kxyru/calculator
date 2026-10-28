import 'package:flutter/foundation.dart';

import '../../../core/utils/number_formatter.dart';
import '../../history/models/history_entry.dart';
import '../../history/services/history_repository.dart';
import '../services/calculation_engine.dart';

class CalculatorController extends ChangeNotifier {
  factory CalculatorController({
    required HistoryRepository historyRepository,
  }) => CalculatorController._(historyRepository);

  CalculatorController._(this._historyRepository);

  static const NumberFormatter _formatter = NumberFormatter();
  static const Set<String> _operators = {'+', '-', '*', '/'};

  final HistoryRepository _historyRepository;
  final CalculationEngine _engine = CalculationEngine();
  String _expression = '';
  String _resultText = '0';
  double _resultValue = 0;
  String? _errorMessage;
  String? _repeatedOperator;
  double? _repeatedOperand;
  bool _justCalculated = false;
  List<HistoryEntry> _history = [];

  String get expression => _expression;
  String get resultText => _resultText;
  double get resultValue => _resultValue;
  String? get errorMessage => _errorMessage;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  Future<void> loadHistory() async {
    _history = _historyRepository.load();
    notifyListeners();
  }

  void inputDigit(String digit) {
    if (digit.length != 1 ||
        digit.codeUnitAt(0) < 48 ||
        digit.codeUnitAt(0) > 57) {
      return;
    }
    _beginInput();
    if (_expression.endsWith(')') || _expression.endsWith('%')) {
      _expression += '*';
    }
    if (_expectsOperand) {
      _expression += digit;
    } else {
      final currentNumber = RegExp(r'\d+(?:\.\d*)?$').firstMatch(_expression);
      if (currentNumber?.group(0) == '0') {
        _expression = _expression.replaceRange(
          currentNumber!.start,
          null,
          digit,
        );
      } else {
        _expression += digit;
      }
    }
    _afterInput();
  }

  void inputDecimal() {
    _beginInput();
    if (_expectsOperand ||
        _expression.endsWith(')') ||
        _expression.endsWith('%')) {
      if (_expression.endsWith(')') || _expression.endsWith('%')) {
        _expression += '*';
      }
      _expression += '0.';
    } else {
      final numberStart = _expression.lastIndexOf(RegExp(r'[+\-*/()]')) + 1;
      final currentNumber = _expression.substring(numberStart);
      if (!currentNumber.contains('.')) _expression += '.';
    }
    _afterInput();
  }

  void inputOperator(String operator) {
    if (!_operators.contains(operator)) return;
    _beginInput(continueFromResult: true);
    if (_expression.isEmpty) {
      if (operator == '-') _expression = '-';
      _afterInput();
      return;
    }
    if (_expression.endsWith('.')) _expression += '0';
    if (_isOperator(_expression[_expression.length - 1])) {
      final trailingMinusIsUnary =
          _expression.endsWith('-') &&
          (_expression.length == 1 ||
              _isOperator(_expression[_expression.length - 2]) ||
              _expression.endsWith('('));
      if (operator == '-' && !trailingMinusIsUnary) {
        _expression += '-';
      } else if (!trailingMinusIsUnary && _expression.length > 1) {
        _expression =
            '${_expression.substring(0, _expression.length - 1)}$operator';
      }
    } else if (_expression.endsWith('(')) {
      if (operator == '-') _expression += '-';
    } else {
      _expression += operator;
    }
    _afterInput();
  }

  void inputPercent() {
    _beginInput(continueFromResult: true);
    if (!_expectsOperand &&
        !_expression.endsWith('%') &&
        !_expression.endsWith('.')) {
      _expression += '%';
    }
    _afterInput();
  }

  void inputParenthesis() {
    _beginInput(continueFromResult: true);
    final openCount = '('.allMatches(_expression).length;
    final closeCount = ')'.allMatches(_expression).length;
    if (_expectsOperand) {
      _expression += '(';
    } else if (openCount > closeCount) {
      _expression += ')';
    } else {
      _expression += '*(';
    }
    _afterInput();
  }

  void toggleSign() {
    _errorMessage = null;
    if (_justCalculated) {
      _expression = _numberForExpression(-_resultValue);
      _justCalculated = false;
      _clearRepeatOperation();
    } else if (_expression.isEmpty || _expectsOperand) {
      _expression += '-';
    } else {
      _toggleLastFactorSign();
    }
    _afterInput();
  }

  void backspace() {
    _errorMessage = null;
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _justCalculated = false;
    _clearRepeatOperation();
    _afterInput();
  }

  void clear() {
    _expression = '';
    _resultValue = 0;
    _resultText = '0';
    _errorMessage = null;
    _justCalculated = false;
    _clearRepeatOperation();
    notifyListeners();
  }

  Future<void> calculate() async {
    try {
      if (_justCalculated &&
          _repeatedOperator != null &&
          _repeatedOperand != null) {
        final previousResult = _resultValue;
        final operator = _repeatedOperator!;
        final operand = _repeatedOperand!;
        final value = _engine.applyOperation(operator, previousResult, operand);
        _expression =
            '${_numberForExpression(previousResult)}$operator${_numberForExpression(operand)}';
        _setResult(value);
        await _recordHistory(_expression, value);
      } else {
        final sourceExpression = _expression;
        final calculation = _engine.evaluate(sourceExpression);
        _repeatedOperator = calculation.repeatedOperator;
        _repeatedOperand = calculation.repeatedOperand;
        _setResult(calculation.value);
        await _recordHistory(sourceExpression, calculation.value);
      }
      _errorMessage = null;
      _justCalculated = true;
    } on CalculationException catch (error) {
      _errorMessage = error.message;
      _justCalculated = false;
    }
    notifyListeners();
  }

  Future<bool> pasteExpression(String value) async {
    final source = value.trim();
    if (source.isEmpty) return false;

    var validGrouping = true;
    final normalized = source.replaceAllMapped(RegExp(r'\d[\d,]*'), (match) {
      final number = match[0]!;
      if (!number.contains(',')) return number;
      if (!RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(number)) {
        validGrouping = false;
        return number;
      }
      return number.replaceAll(',', '');
    });
    if (!validGrouping || normalized.contains(',')) return false;

    try {
      final calculation = _engine.evaluate(normalized);
      _expression = normalized;
      _setResult(calculation.value);
      _errorMessage = null;
      _justCalculated = false;
      _clearRepeatOperation();
      notifyListeners();
      return true;
    } on CalculationException {
      return false;
    }
  }

  Future<void> deleteHistoryEntry(String id) async {
    _history.removeWhere((entry) => entry.id == id);
    await _historyRepository.save(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _historyRepository.save(_history);
    notifyListeners();
  }

  void restoreHistory(HistoryEntry entry) {
    _expression = entry.expression;
    _setResult(entry.result);
    _errorMessage = null;
    _justCalculated = true;
    _clearRepeatOperation();
    notifyListeners();
  }

  bool get _expectsOperand =>
      _expression.isEmpty ||
      _isOperator(_expression[_expression.length - 1]) ||
      _expression.endsWith('(');

  void _beginInput({bool continueFromResult = false}) {
    _errorMessage = null;
    if (_justCalculated) {
      _expression = continueFromResult
          ? _numberForExpression(_resultValue)
          : '';
      _justCalculated = false;
    }
    _clearRepeatOperation();
  }

  void _afterInput() {
    _refreshPreview();
    notifyListeners();
  }

  void _refreshPreview() {
    if (_expression.isEmpty) {
      _resultValue = 0;
      _resultText = '0';
      return;
    }
    try {
      _setResult(_engine.evaluate(_expression).value);
    } on CalculationException {
      // Keep the most recent valid preview while the expression is incomplete.
    }
  }

  void _setResult(double value) {
    _resultValue = value;
    _resultText = _formatter.format(value);
  }

  Future<void> _recordHistory(String expression, double value) async {
    if (_history.isNotEmpty &&
        _history.first.expression == expression &&
        _history.first.result == value) {
      return;
    }
    final now = DateTime.now();
    final entry = HistoryEntry(
      id: '${now.microsecondsSinceEpoch}',
      expression: expression,
      result: value,
      createdAt: now,
    );
    _history = [entry, ..._history].take(HistoryRepository.maxEntries).toList();
    await _historyRepository.save(_history);
  }

  void _toggleLastFactorSign() {
    var end = _expression.length;
    if (_expression.endsWith('%')) end--;
    if (end > 0 && _expression[end - 1] == ')') {
      var depth = 1;
      var start = end - 2;
      while (start >= 0 && depth > 0) {
        if (_expression[start] == ')') depth++;
        if (_expression[start] == '(') depth--;
        start--;
      }
      if (depth == 0) {
        start++;
        if (start > 0 &&
            _expression[start - 1] == '-' &&
            (start == 1 || _isOperator(_expression[start - 2]))) {
          _expression = _expression.replaceRange(start - 1, start, '');
        } else {
          _expression = _expression.replaceRange(start, start, '-');
        }
        return;
      }
    }

    final number = RegExp(r'(?:\d+(?:\.\d*)?|\.\d+)$')
        .firstMatch(_expression.substring(0, end));
    if (number == null) return;
    final start = number.start;
    if (start > 0 &&
        _expression[start - 1] == '-' &&
        (start == 1 || _isOperator(_expression[start - 2]))) {
      _expression = _expression.replaceRange(start - 1, start, '');
    } else {
      _expression = _expression.replaceRange(start, start, '-');
    }
  }

  String _numberForExpression(double value) =>
      value.toString().replaceFirst(RegExp(r'\.0$'), '');

  bool _isOperator(String value) => _operators.contains(value);

  void _clearRepeatOperation() {
    _repeatedOperator = null;
    _repeatedOperand = null;
  }
}
