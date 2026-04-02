import 'dart:convert';
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
    if (username == null) return null;
    return getUserByUsername(username);
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
}

