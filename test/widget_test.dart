import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_calculator/features/calculator/controllers/calculator_controller.dart';
import 'package:offline_calculator/features/history/services/history_repository.dart';
import 'package:offline_calculator/features/settings/controllers/settings_controller.dart';
import 'package:offline_calculator/features/settings/services/settings_repository.dart';
import 'package:offline_calculator/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpCalculator(
    WidgetTester tester, {
    Size size = const Size(400, 800),
  }) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final calculator = CalculatorController(
      historyRepository: HistoryRepository(preferences),
    );
    await calculator.loadHistory();
    await tester.pumpWidget(
      CalculatorApp(
        calculator: calculator,
        settings: SettingsController(SettingsRepository(preferences)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
  }

  testWidgets('renders responsive calculator and calculates chained input', (
    tester,
  ) async {
    String? clipboardText;
    final binaryMessenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      switch (call.method) {
        case 'Clipboard.getData':
          return {'text': clipboardText};
        case 'Clipboard.setData':
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardText = arguments['text'] as String?;
          return null;
        default:
          return null;
      }
    });
    addTearDown(
      () => binaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpCalculator(tester);
    await tapKey(tester, '5');
    await tapKey(tester, '+');
    await tapKey(tester, '3');
    await tapKey(tester, '×');
    await tapKey(tester, '2');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy result'));
    await tester.pumpAndSettle();
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, '11');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tapKey(tester, 'AC');
    await tapKey(tester, '0');
    await tapKey(tester, '.');
    await tapKey(tester, '1');
    await tapKey(tester, '+');
    await tapKey(tester, '0');
    await tapKey(tester, '.');
    await tapKey(tester, '2');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    expect(find.text('0.3'), findsOneWidget);

    await Clipboard.setData(const ClipboardData(text: '9*9'));
    await tester.tap(find.byTooltip('Paste expression'));
    await tester.pumpAndSettle();
    expect(find.text('81'), findsOneWidget);
  });

  testWidgets('clear, backspace, sign, percent, and parentheses work', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKey(tester, '()');
    await tapKey(tester, '4');
    await tapKey(tester, '+');
    await tapKey(tester, '2');
    await tapKey(tester, '()');
    await tapKey(tester, '×');
    await tapKey(tester, '1');
    await tapKey(tester, '0');
    await tapKey(tester, '%');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    expect(find.text('0.6'), findsOneWidget);

    await tester.tap(find.byTooltip('Backspace'));
    await tester.pumpAndSettle();
    expect(find.text('60'), findsOneWidget);
    await tapKey(tester, 'AC');
    await tapKey(tester, '7');
    await tapKey(tester, '+/-');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    expect(find.text('-7'), findsOneWidget);
  });

  testWidgets('recovers from divide-by-zero and supports fast taps', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tapKey(tester, '1');
    await tapKey(tester, '0');
    await tapKey(tester, '÷');
    await tapKey(tester, '0');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    expect(find.text('Cannot divide by zero'), findsOneWidget);

    await tapKey(tester, 'AC');
    for (var index = 0; index < 12; index++) {
      final digit = '${index % 10}';
      await tapKey(tester, digit);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('history restores and deletes calculations', (tester) async {
    await pumpCalculator(tester);
    await tapKey(tester, '8');
    await tapKey(tester, '+');
    await tapKey(tester, '2');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calculation history'));
    await tester.pumpAndSettle();
    expect(find.text('8+2'), findsOneWidget);
    await tester.tap(find.text('8+2'));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);

    await tester.tap(find.byTooltip('Calculation history'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete calculation'));
    await tester.pumpAndSettle();
    expect(find.text('No calculations yet'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapKey(tester, '3');
    await tapKey(tester, '=');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calculation history'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('No calculations yet'), findsOneWidget);
  });

  testWidgets('settings persist theme changes and haptics toggle', (
    tester,
  ) async {
    await pumpCalculator(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Dark theme'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(SettingsRepository.darkThemeKey), isFalse);
    expect(preferences.getBool(SettingsRepository.hapticsKey), isFalse);
  });

  testWidgets('supports physical keyboard input', (tester) async {
    await pumpCalculator(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('avoids overflow on narrow, short, and large text layouts', (
    tester,
  ) async {
    await pumpCalculator(tester, size: const Size(320, 420));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(800, 360);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 720);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
