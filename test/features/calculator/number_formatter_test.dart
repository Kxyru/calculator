import 'package:flutter_test/flutter_test.dart';
import 'package:offline_calculator/core/utils/number_formatter.dart';

void main() {
  const formatter = NumberFormatter();

  test('formats grouped numbers without floating point artifacts', () {
    expect(formatter.format(1234567.89), '1,234,567.89');
    expect(formatter.format(0.1 + 0.2), '0.3');
    expect(formatter.format(42.0), '42');
    expect(formatter.format(-1234.5), '-1,234.5');
  });

  test('uses scientific notation for extreme values', () {
    expect(formatter.format(1e20), '1e+20');
    expect(formatter.format(1e-10), '1e-10');
    expect(formatter.format(double.infinity), 'Infinity');
    expect(formatter.format(double.negativeInfinity), '-Infinity');
    expect(formatter.format(double.nan), 'Not a number');
  });
}
