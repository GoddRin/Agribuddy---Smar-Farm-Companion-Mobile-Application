import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';
import '../models/log_entry.dart';

class LogsNotifier extends StateNotifier<List<LogEntry>> {
  LogsNotifier() : super([]) { state = HiveService.getLogs(); }

  Future<void> addLog(LogEntry log) async {
    await HiveService.saveLog(log);
    state = HiveService.getLogs();
  }

  Future<void> deleteLog(String id) async {
    await HiveService.deleteLog(id);
    state = state.where((l) => l.id != id).toList();
  }

  List<LogEntry> get thisWeekLogs {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return state.where((l) {
      final d = DateTime.tryParse(l.date);
      return d != null && d.isAfter(weekAgo);
    }).toList();
  }
}

final logsProvider = StateNotifierProvider<LogsNotifier, List<LogEntry>>(
  (ref) => LogsNotifier(),
);
