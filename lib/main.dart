import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/calculator/controllers/calculator_controller.dart';
import 'features/calculator/screens/calculator_screen.dart';
import 'features/history/services/history_repository.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/settings/services/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final calculator = CalculatorController(
    historyRepository: HistoryRepository(preferences),
  );
  await calculator.loadHistory();
  runApp(
    CalculatorApp(
      calculator: calculator,
      settings: SettingsController(SettingsRepository(preferences)),
    ),
  );
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({
    required this.calculator,
    required this.settings,
    super.key,
  });

  final CalculatorController calculator;
  final SettingsController settings;

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  @override
  void dispose() {
    widget.calculator.dispose();
    widget.settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) => MaterialApp(
        title: 'Offline Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: widget.settings.isDarkTheme
            ? ThemeMode.dark
            : ThemeMode.light,
        home: CalculatorScreen(
          calculator: widget.calculator,
          settings: widget.settings,
        ),
      ),
    );
  }
}
