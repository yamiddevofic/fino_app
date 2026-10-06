import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'settings_model.g.dart';

const settingsBoxName = 'settingsBox';
const _settingsKey = 'settings';

@HiveType(typeId: 5)
class Settings {
  @HiveField(0)
  bool isDarkMode;

  Settings({this.isDarkMode = false});
}

/// Tema de la app. Sigue al sistema hasta que el usuario elige uno, y
/// recuerda esa elección entre sesiones.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() : _box = Hive.box<Settings>(settingsBoxName);

  final Box<Settings> _box;

  ThemeMode get themeMode {
    final settings = _box.get(_settingsKey);
    if (settings == null) return ThemeMode.system;
    return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _box.put(_settingsKey, Settings(isDarkMode: isDark));
    notifyListeners();
  }
}
