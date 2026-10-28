# Offline Calculator

A native Flutter calculator for Android with an offline expression engine,
calculation history, and persisted appearance/feedback preferences.

## Requirements

- Flutter 3.47.8 or a compatible Flutter stable SDK
- Dart 3.13.7 or compatible (null safety)
- Android SDK and an Android emulator or device for `flutter run`

## Setup

From the project root:

```shell
flutter pub get
```

## Run on Android

Connect an Android device or start an emulator, then run:

```shell
flutter devices
flutter run -d <android-device-id>
```

The app is offline-first. It uses no network service or account.

## Build a debug APK

```shell
flutter build apk --debug
```

The APK is written to:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Checks

```shell
dart format .
flutter analyze
flutter test
```

The test suite covers the pure-Dart parser/evaluator and formatter, calculator
state transitions, SharedPreferences persistence/corruption handling, and
widget interactions/responsive layouts.

## Features

- Precedence-aware arithmetic with parentheses, unary signs, decimals, and
  chained calculations.
- Percent behavior follows the common calculator convention: `50 + 10%` is
  `55`, `50 - 10%` is `45`, while `200 × 10%` is `20`. A trailing percent on
  the right side of addition/subtraction is calculated relative to the left
  operand; standalone and multiplication/division percentages are divided by
  100.
- Repeated equals repeats the final top-level operation and operand.
- Recoverable errors for empty, malformed, too-long, and non-finite
  calculations; operators and decimal input are guarded against invalid
  sequences.
- Persistent history (up to 100 entries), restore/delete/clear actions, and
  duplicate suppression for consecutive identical calculations.
- Persisted light/dark theme (dark by default) and haptics toggle.
- Clipboard copy/paste with expression validation, plus physical keyboard
  input.
- Grouped results and scientific notation for extreme magnitudes.

## Project layout

- `lib/core`: theme and shared number formatting.
- `lib/features/calculator`: pure-Dart expression engine, controller, keypad,
  and calculator screen.
- `lib/features/history`: history model, persistence, and history screen.
- `lib/features/settings`: settings persistence, controller, and settings UI.
- `test`: engine, state/persistence, and widget tests.

## Known limitations

- Calculations use IEEE-754 `double` precision rather than arbitrary precision;
  formatting removes common floating-point display artifacts but cannot make
  the underlying arithmetic exact.
- History is local to the app installation and limited to the newest 100
  entries. Clearing app storage removes it.
- Android is the primary target. No Android emulator or device was connected
  during verification, so on-device runtime behavior was not integration
  tested.
