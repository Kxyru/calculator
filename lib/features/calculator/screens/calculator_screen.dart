import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../history/screens/history_screen.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../settings/screens/settings_screen.dart';
import '../controllers/calculator_controller.dart';
import '../widgets/calculator_key.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({
    required this.calculator,
    required this.settings,
    super.key,
  });

  final CalculatorController calculator;
  final SettingsController settings;

  Future<void> _feedback() async {
    if (settings.hapticsEnabled) await HapticFeedback.selectionClick();
  }

  Future<void> _copyResult(BuildContext context) async {
    if (calculator.errorMessage != null) return;
    await Clipboard.setData(ClipboardData(text: calculator.resultText));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Result copied')));
    }
  }

  Future<void> _paste(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted || data?.text == null) return;
    final accepted = await calculator.pasteExpression(data!.text!);
    if (!accepted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard does not contain a valid expression'),
        ),
      );
    }
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final label = key.keyLabel;
    if (label.length == 1 &&
        label.codeUnitAt(0) >= 48 &&
        label.codeUnitAt(0) <= 57) {
      calculator.inputDigit(label);
    } else if (label == '.') {
      calculator.inputDecimal();
    } else if (label == '+') {
      calculator.inputOperator('+');
    } else if (label == '-') {
      calculator.inputOperator('-');
    } else if (label == '*' || label.toLowerCase() == 'x') {
      calculator.inputOperator('*');
    } else if (label == '/') {
      calculator.inputOperator('/');
    } else if (label == '%') {
      calculator.inputPercent();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.equal) {
      calculator.calculate();
    } else if (key == LogicalKeyboardKey.backspace) {
      calculator.backspace();
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.delete) {
      calculator.clear();
    } else if (label == '(' || label == ')') {
      calculator.inputParenthesis();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _press(Function() action) {
    _feedback();
    action();
  }

  String _displayExpression(String value) =>
      value.replaceAll('*', '×').replaceAll('/', '÷').replaceAll('-', '−');

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 560;
              final veryCompact = constraints.maxHeight < 480;
              return Column(
                children: [
                  SizedBox(
                    height: compact ? 48 : 56,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'CALCULATOR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Paste expression',
                            onPressed: () => _paste(context),
                            icon: const Icon(Icons.content_paste_go_outlined),
                          ),
                          IconButton(
                            tooltip: 'Calculation history',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    HistoryScreen(controller: calculator),
                              ),
                            ),
                            icon: const Icon(Icons.history),
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    SettingsScreen(controller: settings),
                              ),
                            ),
                            icon: const Icon(Icons.tune),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: veryCompact
                        ? 2
                        : compact
                        ? 2
                        : 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: AnimatedBuilder(
                        animation: calculator,
                        builder: (context, _) {
                          final expression = calculator.expression;
                          final expressionColor = Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.62);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      reverse: true,
                                      child: Text(
                                        expression.isEmpty
                                            ? 'Enter a calculation'
                                            : _displayExpression(expression),
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: expressionColor,
                                          fontSize: compact ? 16 : 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Backspace',
                                    onPressed: () =>
                                        _press(calculator.backspace),
                                    icon: const Icon(Icons.backspace_outlined),
                                  ),
                                ],
                              ),
                              if (calculator.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    calculator.errorMessage!,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: compact ? 58 : 68,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        alignment: Alignment.centerRight,
                                        fit: BoxFit.scaleDown,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 140,
                                          ),
                                          child: Text(
                                            calculator.resultText,
                                            key: ValueKey(
                                              calculator.resultText,
                                            ),
                                            maxLines: 1,
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              fontSize: compact ? 42 : 58,
                                              fontWeight: FontWeight.w300,
                                              letterSpacing: -1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy result',
                                      onPressed: calculator.errorMessage == null
                                          ? () => _copyResult(context)
                                          : null,
                                      icon: const Icon(Icons.copy_outlined),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: veryCompact
                        ? 3
                        : compact
                        ? 5
                        : 6,
                    child: _Keypad(
                      onDigit: (digit) =>
                          _press(() => calculator.inputDigit(digit)),
                      onOperator: (operator) =>
                          _press(() => calculator.inputOperator(operator)),
                      onClear: () => _press(calculator.clear),
                      onSign: () => _press(calculator.toggleSign),
                      onPercent: () => _press(calculator.inputPercent),
                      onParenthesis: () => _press(calculator.inputParenthesis),
                      onDecimal: () => _press(calculator.inputDecimal),
                      onEquals: () => _press(calculator.calculate),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onOperator,
    required this.onClear,
    required this.onSign,
    required this.onPercent,
    required this.onParenthesis,
    required this.onDecimal,
    required this.onEquals,
  });

  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onClear;
  final VoidCallback onSign;
  final VoidCallback onPercent;
  final VoidCallback onParenthesis;
  final VoidCallback onDecimal;
  final VoidCallback onEquals;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [
        _key('AC', 'All clear', onClear, CalculatorKeyStyle.utility),
        _key('+/-', 'Toggle sign', onSign, CalculatorKeyStyle.utility),
        _key('%', 'Percent', onPercent, CalculatorKeyStyle.utility),
        _key('÷', 'Divide', () => onOperator('/'), CalculatorKeyStyle.operator),
      ],
      [
        _numberKey('7'),
        _numberKey('8'),
        _numberKey('9'),
        _key(
          '×',
          'Multiply',
          () => onOperator('*'),
          CalculatorKeyStyle.operator,
        ),
      ],
      [
        _numberKey('4'),
        _numberKey('5'),
        _numberKey('6'),
        _key(
          '−',
          'Subtract',
          () => onOperator('-'),
          CalculatorKeyStyle.operator,
        ),
      ],
      [
        _numberKey('1'),
        _numberKey('2'),
        _numberKey('3'),
        _key('+', 'Add', () => onOperator('+'), CalculatorKeyStyle.operator),
      ],
      [
        _key('()', 'Parentheses', onParenthesis, CalculatorKeyStyle.utility),
        _numberKey('0'),
        _key('.', 'Decimal point', onDecimal, CalculatorKeyStyle.utility),
        _key('=', 'Equals', onEquals, CalculatorKeyStyle.equals),
      ],
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumRowHeight = 56.0;
        if (constraints.maxHeight < minimumRowHeight * rows.length) {
          return SingleChildScrollView(
            child: Column(
              children: [
                for (final row in rows)
                  SizedBox(height: minimumRowHeight, child: _buildRow(row)),
              ],
            ),
          );
        }
        return Column(
          children: [for (final row in rows) Expanded(child: _buildRow(row))],
        );
      },
    );
  }

  Widget _buildRow(List<Widget> keys) =>
      Row(children: [for (final key in keys) Expanded(child: key)]);

  Widget _numberKey(String digit) =>
      _key(digit, digit, () => onDigit(digit), CalculatorKeyStyle.number);

  Widget _key(
    String label,
    String semanticLabel,
    VoidCallback action,
    CalculatorKeyStyle style,
  ) => CalculatorKey(
    label: label,
    semanticLabel: semanticLabel,
    onPressed: action,
    style: style,
  );
}
