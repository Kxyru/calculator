class CalculationException implements Exception {
  const CalculationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalculationResult {
  const CalculationResult({
    required this.value,
    this.repeatedOperator,
    this.repeatedOperand,
  });

  final double value;
  final String? repeatedOperator;
  final double? repeatedOperand;
}

class CalculationEngine {
  static const int maxExpressionLength = 512;
  static const int maxTokenCount = 256;

  CalculationResult evaluate(String expression) {
    if (expression.trim().isEmpty) {
      throw const CalculationException('Enter an expression');
    }
    if (expression.length > maxExpressionLength) {
      throw const CalculationException('Expression is too long');
    }

    final parser = _Parser(_tokenize(expression));
    final root = parser.parse();
    final value = root.evaluate();
    if (!value.isFinite) {
      throw const CalculationException('Result is not a finite number');
    }

    final repeatedOperator = root is _BinaryNode ? root.operator : null;
    var repeatedOperand = root is _BinaryNode ? root.right.evaluate() : null;
    if (root is _BinaryNode &&
        (root.operator == '+' || root.operator == '-') &&
        root.right is _PercentNode) {
      repeatedOperand = repeatedOperand! * root.left.evaluate();
    }
    return CalculationResult(
      value: value,
      repeatedOperator: repeatedOperator,
      repeatedOperand: repeatedOperand,
    );
  }

  double applyOperation(String operator, double left, double right) {
    final result = switch (operator) {
      '+' => left + right,
      '-' => left - right,
      '*' => left * right,
      '/' =>
        right == 0
            ? throw const CalculationException('Cannot divide by zero')
            : left / right,
      _ => throw const CalculationException('Invalid operation'),
    };
    if (!result.isFinite) {
      throw const CalculationException('Result is not a finite number');
    }
    return result;
  }

  List<_Token> _tokenize(String expression) {
    final tokens = <_Token>[];
    var index = 0;
    while (index < expression.length) {
      final char = expression[index];
      if (char.trim().isEmpty) {
        index++;
        continue;
      }

      if (_isDigit(char) || char == '.') {
        final match = RegExp(
          r'(?:(?:\d+(?:\.\d*)?)|(?:\.\d+))(?:[eE][+-]?\d+)?',
        ).matchAsPrefix(expression, index);
        if (match == null) {
          throw const CalculationException('Invalid number');
        }
        final text = match[0]!;
        index = match.end;
        final value = double.tryParse(text);
        if (value == null) {
          throw const CalculationException('Invalid number');
        }
        tokens.add(_Token.number(value));
      } else {
        final operator = switch (char) {
          '×' => '*',
          '÷' => '/',
          '−' => '-',
          '+' || '-' || '*' || '/' || '%' || '(' || ')' => char,
          _ => throw const CalculationException('Invalid character'),
        };
        tokens.add(_Token.symbol(operator));
        index++;
      }

      if (tokens.length > maxTokenCount) {
        throw const CalculationException('Expression is too complex');
      }
    }
    return tokens;
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
}

class _Token {
  const _Token.number(this.numberValue) : symbolValue = null;
  const _Token.symbol(this.symbolValue) : numberValue = null;

  final double? numberValue;
  final String? symbolValue;
}

abstract class _Node {
  double evaluate();
}

class _NumberNode extends _Node {
  _NumberNode(this.value);

  final double value;

  @override
  double evaluate() => value;
}

class _UnaryNode extends _Node {
  _UnaryNode(this.operator, this.operand);

  final String operator;
  final _Node operand;

  @override
  double evaluate() {
    final value = operand.evaluate();
    return operator == '-' ? -value : value;
  }
}

class _PercentNode extends _Node {
  _PercentNode(this.operand);

  final _Node operand;

  @override
  double evaluate() => operand.evaluate() / 100;
}

class _BinaryNode extends _Node {
  _BinaryNode(this.operator, this.left, this.right);

  final String operator;
  final _Node left;
  final _Node right;

  @override
  double evaluate() {
    final leftValue = left.evaluate();
    var rightValue = right.evaluate();
    if ((operator == '+' || operator == '-') && right is _PercentNode) {
      rightValue *= leftValue;
    }
    return switch (operator) {
      '+' => leftValue + rightValue,
      '-' => leftValue - rightValue,
      '*' => leftValue * rightValue,
      '/' =>
        rightValue == 0
            ? throw const CalculationException('Cannot divide by zero')
            : leftValue / rightValue,
      _ => throw const CalculationException('Invalid operation'),
    };
  }
}

class _Parser {
  _Parser(this.tokens);

  final List<_Token> tokens;
  int _position = 0;

  _Node parse() {
    if (tokens.isEmpty) {
      throw const CalculationException('Enter an expression');
    }
    final expression = _parseExpression();
    if (_position != tokens.length) {
      throw const CalculationException('Malformed expression');
    }
    return expression;
  }

  _Node _parseExpression() {
    var node = _parseTerm();
    while (_match('+') || _match('-')) {
      final operator = tokens[_position - 1].symbolValue!;
      node = _BinaryNode(operator, node, _parseTerm());
    }
    return node;
  }

  _Node _parseTerm() {
    var node = _parseUnary();
    while (_match('*') || _match('/')) {
      final operator = tokens[_position - 1].symbolValue!;
      node = _BinaryNode(operator, node, _parseUnary());
    }
    return node;
  }

  _Node _parseUnary() {
    if (_match('+')) {
      return _UnaryNode('+', _parseUnary());
    }
    if (_match('-')) {
      return _UnaryNode('-', _parseUnary());
    }
    var node = _parsePrimary();
    while (_match('%')) {
      node = _PercentNode(node);
    }
    return node;
  }

  _Node _parsePrimary() {
    if (_match('(')) {
      final node = _parseExpression();
      if (!_match(')')) {
        throw const CalculationException('Missing closing parenthesis');
      }
      return node;
    }
    if (_position >= tokens.length) {
      throw const CalculationException('Incomplete expression');
    }
    final token = tokens[_position++];
    final value = token.numberValue;
    if (value == null) {
      throw const CalculationException('Expected a number');
    }
    return _NumberNode(value);
  }

  bool _match(String symbol) {
    if (_position >= tokens.length || tokens[_position].symbolValue != symbol) {
      return false;
    }
    _position++;
    return true;
  }
}
