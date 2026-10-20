import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';

abstract interface class AppearanceLocalDataSource {
  /// Null si nunca se guardó un tema.
  Future<ThemePreference?> getThemePreference();

  Future<void> saveThemePreference(ThemePreference theme);
}

class AppearanceLocalDataSourceImpl implements AppearanceLocalDataSource {
  const AppearanceLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _themeKey = 'theme_preference';

  @override
  Future<ThemePreference?> getThemePreference() async {
    try {
      final name = await _prefs.getString(_themeKey);
      return ThemePreference.values.asNameMap()[name];
    } catch (error) {
      throw CacheException('$error');
    }
  }

  @override
  Future<void> saveThemePreference(ThemePreference theme) async {
    try {
      await _prefs.setString(_themeKey, theme.name);
    } catch (error) {
      throw CacheException('$error');
    }
  }
}
