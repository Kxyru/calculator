import 'package:flutter_test/flutter_test.dart';
import 'package:offline_calculator/features/history/models/history_entry.dart';
import 'package:offline_calculator/features/history/services/history_repository.dart';
import 'package:offline_calculator/features/settings/controllers/settings_controller.dart';
import 'package:offline_calculator/features/settings/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'persists theme, haptics, and history between repository instances',
    () async {
      SharedPreferences.setMockInitialValues({});
      var preferences = await SharedPreferences.getInstance();
      final settings = SettingsController(SettingsRepository(preferences));
      await settings.setDarkTheme(false);
      await settings.setHapticsEnabled(false);

      final entry = HistoryEntry(
        id: 'one',
        expression: '2+2',
        result: 4,
        createdAt: DateTime.utc(2026),
      );
      await HistoryRepository(preferences).save([entry]);

      preferences = await SharedPreferences.getInstance();
      final restoredSettings = SettingsController(
        SettingsRepository(preferences),
      );
      expect(restoredSettings.isDarkTheme, isFalse);
      expect(restoredSettings.hapticsEnabled, isFalse);
      expect(HistoryRepository(preferences).load().single.expression, '2+2');
    },
  );

  test('handles corrupted and partially invalid history safely', () async {
    SharedPreferences.setMockInitialValues({
      HistoryRepository.storageKey: '[{"id":"ok","expression":"3+4","result":7,"createdAt":"2026-01-01T00:00:00Z"},{"id":3}]',
    });
    final preferences = await SharedPreferences.getInstance();
    expect(HistoryRepository(preferences).load(), hasLength(1));

    SharedPreferences.setMockInitialValues({
      HistoryRepository.storageKey: 'not json',
    });
    final corrupted = await SharedPreferences.getInstance();
    expect(HistoryRepository(corrupted).load(), isEmpty);
  });
}
