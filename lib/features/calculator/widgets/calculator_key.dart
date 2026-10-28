import 'package:flutter/material.dart';

enum CalculatorKeyStyle { number, utility, operator, equals }

class CalculatorKey extends StatelessWidget {
  const CalculatorKey({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.style = CalculatorKeyStyle.number,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;
  final CalculatorKeyStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = switch (style) {
      CalculatorKeyStyle.equals => scheme.onPrimary,
      CalculatorKeyStyle.operator => scheme.primary,
      CalculatorKeyStyle.number ||
      CalculatorKeyStyle.utility => scheme.onSurface,
    };
    final background = switch (style) {
      CalculatorKeyStyle.equals => scheme.primary,
      CalculatorKeyStyle.operator => scheme.primary.withValues(alpha: 0.12),
      CalculatorKeyStyle.number =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF252A2D)
            : const Color(0xFFE5EAE7),
      CalculatorKeyStyle.utility =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF303638)
            : const Color(0xFFD9E0DC),
    };
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(22),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: label.length > 2 ? 18 : 24,
                  fontWeight: style == CalculatorKeyStyle.equals
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
