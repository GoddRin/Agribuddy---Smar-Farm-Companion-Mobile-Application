import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';

class SettingsNotifier extends StateNotifier<Map<String, String>> {
  SettingsNotifier() : super({
    'isMusicEnabled': 'true',
    'isSoundEnabled': 'true',
    'isTtsEnabled': 'true',
    'language': 'en',
    'isDarkMode': 'false',
    'musicVolume': '0.55',
    'sfxVolume': '0.8',
    'voiceVolume': '1.0',
  }) { _load(); }

  void _load() {
    final key = HiveService.geminiApiKey;
    state = {
      'geminiApiKey': key ?? '',
      'isDarkMode': HiveService.isDarkMode ? 'true' : 'false',
      'language': HiveService.language,
      'isSoundEnabled': HiveService.isSoundEnabled ? 'true' : 'false',
      'isMusicEnabled': HiveService.isMusicEnabled ? 'true' : 'false',
      'isTtsEnabled': HiveService.isTtsEnabled ? 'true' : 'false',
      'musicVolume': HiveService.musicVolume.toString(),
      'sfxVolume': HiveService.sfxVolume.toString(),
      'voiceVolume': HiveService.voiceVolume.toString(),
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

  Future<void> toggleTts(bool enabled) async {
    await HiveService.setTtsEnabled(enabled);
    state = {...state, 'isTtsEnabled': enabled ? 'true' : 'false'};
  }

  Future<void> toggleSound(bool enabled) async {
    await HiveService.setSoundEnabled(enabled);
    state = {...state, 'isSoundEnabled': enabled ? 'true' : 'false'};
  }

  Future<void> toggleMusic(bool enabled) async {
    await HiveService.setMusicEnabled(enabled);
    state = {...state, 'isMusicEnabled': enabled ? 'true' : 'false'};
  }

  Future<void> setMusicVolume(double vol) async {
    await HiveService.setMusicVolume(vol);
    state = {...state, 'musicVolume': vol.toString()};
  }

  Future<void> setSfxVolume(double vol) async {
    await HiveService.setSfxVolume(vol);
    state = {...state, 'sfxVolume': vol.toString()};
  }

  Future<void> setVoiceVolume(double vol) async {
    await HiveService.setVoiceVolume(vol);
    state = {...state, 'voiceVolume': vol.toString()};
  }

  String get geminiApiKey => state['geminiApiKey'] ?? '';
  bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  bool get isDarkMode => state['isDarkMode'] == 'true';
  String get language => state['language'] ?? 'en';
  bool get isSoundEnabled => state['isSoundEnabled'] != 'false';
  bool get isMusicEnabled => state['isMusicEnabled'] != 'false';
  bool get isTtsEnabled => state['isTtsEnabled'] != 'false';

  double get musicVolume => double.tryParse(state['musicVolume'] ?? '0.55') ?? 0.55;
  double get sfxVolume => double.tryParse(state['sfxVolume'] ?? '0.8') ?? 0.8;
  double get voiceVolume => double.tryParse(state['voiceVolume'] ?? '1.0') ?? 1.0;
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, String>>(
  (ref) => SettingsNotifier(),
);
