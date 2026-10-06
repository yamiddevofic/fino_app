import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 5)
class Settings {
  @HiveField(0)
  bool isDarkMode;

  Settings({this.isDarkMode = false});
}

class SettingsProvider extends ChangeNotifier {
  static SettingsProvider of(BuildContext context) =>
      context.read<SettingsProvider>();

  Settings _settings = Settings();

  Settings get settings => _settings;

  bool get isDarkMode => _settings.isDarkMode;

  Future<void> load() async {
    final box = await Hive.openBox<Settings>('settingsBox');
    _settings = box.get('settings', defaultValue: Settings()) ?? Settings();
    notifyListeners();
  }

  Future<void> toggleTheme({required bool isDark}) async {
    final box = await Hive.openBox<Settings>('settingsBox');
    _settings = Settings(isDarkMode: isDark);
    await box.put('settings', _settings);
    notifyListeners();
  }

  ThemeMode get themeMode =>
      _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
