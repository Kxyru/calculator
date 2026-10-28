import 'package:flutter/material.dart';

class AppTheme {
  static const Color _accent = Color(0xFF9FE3C0);

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: const Color(0xFF121416),
    surface: const Color(0xFF202427),
    foreground: const Color(0xFFF4F6F5),
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: const Color(0xFFF3F5F4),
    surface: Colors.white,
    foreground: const Color(0xFF171B19),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color foreground,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
      surface: background,
      primary: _accent,
      onPrimary: const Color(0xFF101A14),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: scheme,
      ).black.apply(bodyColor: foreground, displayColor: foreground),
      iconTheme: IconThemeData(color: foreground),
      dividerColor: foreground.withValues(alpha: 0.1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: foreground),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: foreground),
      ),
    );
  }
}
