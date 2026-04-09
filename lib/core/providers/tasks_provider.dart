import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';
import '../models/task_item.dart';

class TasksNotifier extends StateNotifier<List<TaskItem>> {
  TasksNotifier() : super([]) { state = HiveService.getTasks(); }

  Future<void> addTask(TaskItem task) async {
    await HiveService.saveTask(task);
    state = HiveService.getTasks();
  }

  Future<void> toggleComplete(String id) async {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    state[idx].isCompleted = !state[idx].isCompleted;
    await HiveService.saveTask(state[idx]);
    state = [...state];
  }

  Future<void> deleteTask(String id) async {
    await HiveService.deleteTask(id);
    state = state.where((t) => t.id != id).toList();
  }

  List<TaskItem> get todayTasks =>
      state.where((t) => !t.isCompleted && t.isDueToday).toList();

  List<TaskItem> get overdueTasks =>
      state.where((t) => t.isOverdue).toList();

  List<TaskItem> get pendingTasks =>
      state.where((t) => !t.isCompleted).toList();

  bool get hasUnsynced => state.any((t) => !t.isSynced);
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskItem>>(
  (ref) => TasksNotifier(),
);
