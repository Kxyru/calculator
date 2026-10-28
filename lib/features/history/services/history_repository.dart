import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

class HistoryRepository {
  HistoryRepository(this._preferences);

  static const String storageKey = 'calculator_history';
  static const int maxEntries = 100;

  final SharedPreferences _preferences;

  List<HistoryEntry> load() {
    final encoded = _preferences.getString(storageKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .map(HistoryEntry.fromJson)
          .whereType<HistoryEntry>()
          .take(maxEntries)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<HistoryEntry> entries) async {
    await _preferences.setString(
      storageKey,
      jsonEncode(
        entries.take(maxEntries).map((entry) => entry.toJson()).toList(),
      ),
    );
  }
}
