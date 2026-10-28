class NumberFormatter {
  const NumberFormatter();

  static const int _fractionDigits = 10;

  String format(double value) {
    if (value.isNaN) return 'Not a number';
    if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
    if (value == 0) return '0';

    final absolute = value.abs();
    if (absolute >= 1e15 || absolute < 1e-8) {
      return _formatScientific(value);
    }

    var fixed = value.toString();
    final sourceDecimalIndex = fixed.indexOf('.');
    if (sourceDecimalIndex >= 0 &&
        fixed.length - sourceDecimalIndex - 1 > _fractionDigits) {
      fixed = value.toStringAsFixed(_fractionDigits);
    }
    fixed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    final negative = fixed.startsWith('-');
    if (negative) fixed = fixed.substring(1);
    final resultDecimalIndex = fixed.indexOf('.');
    final integer = resultDecimalIndex < 0
        ? fixed
        : fixed.substring(0, resultDecimalIndex);
    final fraction = resultDecimalIndex < 0
        ? ''
        : fixed.substring(resultDecimalIndex);
    final grouped = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${negative ? '-' : ''}$grouped$fraction';
  }

  String _formatScientific(double value) {
    final parts = value.toStringAsExponential(6).split('e');
    final mantissa = parts[0].replaceFirst(RegExp(r'\.?0+$'), '');
    final exponent = int.parse(parts[1]);
    return '${mantissa}e${exponent >= 0 ? '+' : ''}$exponent';
  }
}
