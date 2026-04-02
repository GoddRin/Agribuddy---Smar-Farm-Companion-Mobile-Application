import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';

class SettingsNotifier extends StateNotifier<Map<String, String>> {
  SettingsNotifier() : super({}) { _load(); }

  void _load() {
    final key = HiveService.geminiApiKey;
    state = {
      'geminiApiKey': key ?? '',
      'isDarkMode': HiveService.isDarkMode ? 'true' : 'false',
      'language': HiveService.language,
    };
  }

  Future<void> setGeminiApiKey(String key) async {
    await HiveService.setGeminiApiKey(key.trim());
    state = {...state, 'geminiApiKey': key.trim()};
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await HiveService.setDarkMode(isDark);
    state = {...state, 'isDarkMode': isDark ? 'true' : 'false'};
  }

  Future<void> setLanguage(String lang) async {
    await HiveService.setLanguage(lang);
    state = {...state, 'language': lang};
  }

  String get geminiApiKey => state['geminiApiKey'] ?? '';
  bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  bool get isDarkMode => state['isDarkMode'] == 'true';
  String get language => state['language'] ?? 'en';
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, String>>(
  (ref) => SettingsNotifier(),
);
