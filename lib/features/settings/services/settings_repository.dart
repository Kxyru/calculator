import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  static const String darkThemeKey = 'settings_dark_theme';
  static const String hapticsKey = 'settings_haptics';

  final SharedPreferences _preferences;

  bool get isDarkTheme => _preferences.getBool(darkThemeKey) ?? true;
  bool get hapticsEnabled => _preferences.getBool(hapticsKey) ?? true;

  Future<void> setDarkTheme(bool value) =>
      _preferences.setBool(darkThemeKey, value);

  Future<void> setHapticsEnabled(bool value) =>
      _preferences.setBool(hapticsKey, value);
}
