import 'package:flutter/foundation.dart';

import '../services/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository)
    : _isDarkTheme = _repository.isDarkTheme,
      _hapticsEnabled = _repository.hapticsEnabled;

  final SettingsRepository _repository;
  bool _isDarkTheme;
  bool _hapticsEnabled;

  bool get isDarkTheme => _isDarkTheme;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> setDarkTheme(bool value) async {
    if (_isDarkTheme == value) return;
    _isDarkTheme = value;
    notifyListeners();
    await _repository.setDarkTheme(value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_hapticsEnabled == value) return;
    _hapticsEnabled = value;
    notifyListeners();
    await _repository.setHapticsEnabled(value);
  }
}
