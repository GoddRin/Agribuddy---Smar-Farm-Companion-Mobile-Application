import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/log_entry.dart';
import '../models/task_item.dart';
import '../models/expense_item.dart';
import '../providers/crop_provider.dart';

class HiveService {
  static late Box<String> _users;
  static late Box<String> _logs;
  static late Box<String> _tasks;
  static late Box<String> _expenses;
  static late Box<String> _crops;
  static late Box<String> _settings;

  static const _defaultGeminiKey = 'AIzaSyAWCVz32HQeRVog77JX6xwa-4Pxr4RvFR0';

  static Future<void> init() async {
    await Hive.initFlutter();
    _users    = await Hive.openBox<String>('users');
    _logs     = await Hive.openBox<String>('logs');
    _tasks    = await Hive.openBox<String>('tasks');
    _expenses = await Hive.openBox<String>('expenses');
    _crops    = await Hive.openBox<String>('crops');
    _settings = await Hive.openBox<String>('settings');

    // Pre-seed Gemini key if not already set
    if ((_settings.get('geminiApiKey') ?? '').isEmpty) {
      await _settings.put('geminiApiKey', _defaultGeminiKey);
    }

    // Pre-seed music setting to ON by default
    if (_settings.get('isMusicEnabled') == null) {
      await _settings.put('isMusicEnabled', 'true');
    }
  }

  // ─── Settings ─────────────────────────────────────────────
  static String? getSetting(String key) => _settings.get(key);
  static Future<void> setSetting(String key, String value) => _settings.put(key, value);

  // ─── Users ─────────────────────────────────────────────────
  static Future<void> saveUser(UserModel u) =>
      _users.put(u.username.toLowerCase(), jsonEncode(u.toJson()));
  static UserModel? getUserByUsername(String username) {
    final raw = _users.get(username.toLowerCase().trim());
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }
  // Legacy email lookup (for future Firebase migration)
  static UserModel? getUserByEmail(String email) {
    for (final raw in _users.values) {
      final u = UserModel.fromJson(jsonDecode(raw));
      if (u.email.toLowerCase() == email.toLowerCase()) return u;
    }
    return null;
  }

  // ─── Auth session ──────────────────────────────────────────
  static String? get currentUserId => _settings.get('currentUserId');
  static String? get currentUsername => _settings.get('currentUsername');
  static Future<void> saveSession(UserModel u) async {
    await _settings.put('currentUserId', u.id);
    await _settings.put('currentUsername', u.username.toLowerCase());
  }
  static Future<void> clearSession() async {
    await _settings.delete('currentUserId');
    await _settings.delete('currentUsername');
  }
  static bool get isLoggedIn => currentUserId != null;
  static bool get onboardingDone => _settings.get('onboardingDone') == 'true';
  static Future<void> setOnboardingDone() => _settings.put('onboardingDone', 'true');

  static UserModel? get currentUser {
    final username = currentUsername;
    debugPrint("HiveSession: Checking persistence... currentUsername: $username");
    
    if (username != null) {
      final u = getUserByUsername(username);
      if (u != null) {
        debugPrint("HiveSession: Restored session for @${u.username}");
        return u;
      }
      debugPrint("HiveSession: Username found but user data missing in box!");
    }
    
    // Recovery Logic: If no session but users exist, auto-login the first one
    if (_users.isNotEmpty) {
      try {
        final firstRaw = _users.values.first;
        final recovered = UserModel.fromJson(jsonDecode(firstRaw));
        debugPrint("HiveSession: Recovered user @${recovered.username} from box (Auto-login)");
        // Silently restore session
        saveSession(recovered);
        return recovered;
      } catch (e) {
        debugPrint("HiveSession: Recovery Error: $e");
      }
    }
    debugPrint("HiveSession: No session or user data found.");
    return null;
  }

  // ─── Logs ──────────────────────────────────────────────────
  static Future<void> saveLog(LogEntry l) =>
      _logs.put(l.id, jsonEncode(l.toJson()));
  static Future<void> deleteLog(String id) => _logs.delete(id);
  static List<LogEntry> getLogs() =>
      _logs.values.map((s) => LogEntry.fromJson(jsonDecode(s))).toList()
        ..sort((a, b) => '${b.date} ${b.time}'.compareTo('${a.date} ${a.time}'));

  // ─── Tasks ─────────────────────────────────────────────────
  static Future<void> saveTask(TaskItem t) =>
      _tasks.put(t.id, jsonEncode(t.toJson()));
  static Future<void> deleteTask(String id) => _tasks.delete(id);
  static List<TaskItem> getTasks() =>
      _tasks.values.map((s) => TaskItem.fromJson(jsonDecode(s))).toList()
        ..sort((a, b) => '${a.dueDate} ${a.dueTime}'.compareTo('${b.dueDate} ${b.dueTime}'));

  // ─── Expenses ──────────────────────────────────────────────
  static Future<void> saveExpense(ExpenseItem e) =>
      _expenses.put(e.id, jsonEncode(e.toJson()));
  static Future<void> deleteExpense(String id) => _expenses.delete(id);
  static List<ExpenseItem> getExpenses() =>
      _expenses.values.map((s) => ExpenseItem.fromJson(jsonDecode(s))).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // ─── Crops ─────────────────────────────────────────────────
  static Future<void> saveCrop(Crop c) =>
      _crops.put(c.id, jsonEncode(c.toJson()));
  static Future<void> deleteCrop(String id) => _crops.delete(id);
  static List<Crop> getCrops() =>
      _crops.values.map((s) => Crop.fromJson(jsonDecode(s))).toList();

  // ─── Gemini API Key ────────────────────────────────────────
  static String? get geminiApiKey => _settings.get('geminiApiKey');
  static Future<void> setGeminiApiKey(String key) =>
      _settings.put('geminiApiKey', key);

  // ─── App Preferences ───────────────────────────────────────
  static bool get isDarkMode => _settings.get('isDarkMode') == 'true';
  static Future<void> setDarkMode(bool dark) => _settings.put('isDarkMode', dark ? 'true' : 'false');

  static String get language => _settings.get('language') ?? 'en';
  static Future<void> setLanguage(String lang) => _settings.put('language', lang);

  static bool get isSoundEnabled => _settings.get('isSoundEnabled') != 'false';
  static Future<void> setSoundEnabled(bool enabled) => _settings.put('isSoundEnabled', enabled ? 'true' : 'false');

  static bool get isMusicEnabled => _settings.get('isMusicEnabled') == 'true' || _settings.get('isMusicEnabled') == null;
  static Future<void> setMusicEnabled(bool enabled) => _settings.put('isMusicEnabled', enabled ? 'true' : 'false');

  static bool get isTtsEnabled => _settings.get('isTtsEnabled') != 'false';
  static Future<void> setTtsEnabled(bool enabled) => _settings.put('isTtsEnabled', enabled ? 'true' : 'false');

  static double get musicVolume => double.tryParse(_settings.get('musicVolume') ?? '0.55') ?? 0.55;
  static Future<void> setMusicVolume(double vol) => _settings.put('musicVolume', vol.toString());

  static double get sfxVolume => double.tryParse(_settings.get('sfxVolume') ?? '0.8') ?? 0.8;
  static Future<void> setSfxVolume(double vol) => _settings.put('sfxVolume', vol.toString());

  static double get voiceVolume => double.tryParse(_settings.get('voiceVolume') ?? '1.0') ?? 1.0;
  static Future<void> setVoiceVolume(double vol) => _settings.put('voiceVolume', vol.toString());
}

