import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';
import '../models/expense_item.dart';

class ExpensesNotifier extends StateNotifier<List<ExpenseItem>> {
  ExpensesNotifier() : super([]) { state = HiveService.getExpenses(); }

  Future<void> addExpense(ExpenseItem expense) async {
    await HiveService.saveExpense(expense);
    state = HiveService.getExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await HiveService.deleteExpense(id);
    state = state.where((e) => e.id != id).toList();
  }

  double get totalAllTime =>
      state.fold(0.0, (sum, e) => sum + e.amount);

  double get totalThisMonth {
    final now = DateTime.now();
    return state.where((e) {
      final d = DateTime.tryParse(e.date);
      return d != null && d.month == now.month && d.year == now.year;
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get byCategory {
    final map = <String, double>{};
    for (final e in state) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Map<String, double> get thisMonthByCategory {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final e in state) {
      final d = DateTime.tryParse(e.date);
      if (d != null && d.month == now.month && d.year == now.year) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    return map;
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<ExpenseItem>>(
  (ref) => ExpensesNotifier(),
);
