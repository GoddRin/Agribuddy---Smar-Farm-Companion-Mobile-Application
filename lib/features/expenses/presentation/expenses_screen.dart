import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/expense_item.dart';
import '../../../core/providers/expenses_provider.dart';
import '../../../core/localization/app_localizations.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});
  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final notifier = ref.read(expensesProvider.notifier);
    final theme = Theme.of(context);
    final byCategory = notifier.thisMonthByCategory;
    final total = notifier.totalThisMonth;

    return Scaffold(
      appBar: AppBar(title: Text(ref.t('Expense Tracker')), actions: [
        IconButton(icon: const Icon(LucideIcons.plus), onPressed: () => _openAddSheet(context, ref)),
      ]),
      body: expenses.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.dollarSign, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(ref.t('No expenses yet'), style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 16),
              ElevatedButton.icon(icon: const Icon(LucideIcons.plus), label: Text(ref.t('Add Expense')), onPressed: () => _openAddSheet(context, ref)),
            ]))
          : ListView(padding: const EdgeInsets.all(16), children: [
              // Monthly summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ref.t('This Month'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('₱${total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${ref.t('Total expenses')}: ${expenses.where((e) {
                    final now = DateTime.now();
                    final d = DateTime.tryParse(e.date);
                    return d != null && d.month == now.month && d.year == now.year;
                  }).length}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ).animate().fadeIn().slideY(begin: -0.1),
              const SizedBox(height: 20),

              // Bar chart by category
              if (byCategory.isNotEmpty) ...[
                Text(ref.t('By Category (This Month)'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: (byCategory.values.isEmpty ? 100 : byCategory.values.reduce((a, b) => a > b ? a : b)) * 1.3,
                    barGroups: byCategory.entries.toList().asMap().entries.map((e) {
                      final color = _catColor(e.value.key);
                      return BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(toY: e.value.value, color: color, width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                      ]);
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                        final keys = byCategory.keys.toList();
                        if (v.toInt() >= keys.length) return const Text('');
                        return Padding(padding: const EdgeInsets.only(top: 4),
                          child: Text(ref.t(keys[v.toInt()]).substring(0, 3), style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700], fontSize: 10)));
                      })),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  )),
                ),
                const SizedBox(height: 20),
              ],

              Text(ref.t('All Expenses'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...expenses.asMap().entries.map((e) => _ExpenseCard(expense: e.value)
                  .animate().fadeIn(delay: Duration(milliseconds: e.key * 40)).slideY(begin: 0.1)),
              const SizedBox(height: 80),
            ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  static void _openAddSheet(BuildContext ctx, WidgetRef ref) => showModalBottomSheet(
    context: ctx, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _AddExpenseSheet(ref: ref),
  );

  Color _catColor(String cat) {
    switch (cat) {
      case 'Seeds': return Colors.green;
      case 'Fertilizer': return Colors.orange;
      case 'Pesticides': return Colors.red;
      case 'Labor': return Colors.blue;
      case 'Transport': return Colors.purple;
      case 'Equipment': return Colors.teal;
      default: return Colors.grey;
    }
  }
}

class _ExpenseCard extends ConsumerWidget {
  final ExpenseItem expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _color(expense.category);
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
        child: const Icon(LucideIcons.trash2, color: Colors.white)),
      onDismissed: (_) => ref.read(expensesProvider.notifier).deleteExpense(expense.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(LucideIcons.dollarSign, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ref.t(expense.category), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (expense.note.isNotEmpty) Text(expense.note, style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[500], fontSize: 12)),
            Text(expense.date, style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400], fontSize: 11)),
          ])),
          Text('₱${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }

  Color _color(String cat) {
    switch (cat) {
      case 'Seeds': return Colors.green;
      case 'Fertilizer': return Colors.orange;
      case 'Pesticides': return Colors.red;
      case 'Labor': return Colors.blue;
      case 'Transport': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddExpenseSheet({required this.ref});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = expenseCategories[0];
  String _date = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void dispose() { _amountCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'))); return; }
    widget.ref.read(expensesProvider.notifier).addExpense(ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _category, amount: amount, date: _date, note: _noteCtrl.text.trim(),
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₱${amount.toStringAsFixed(2)} ${widget.ref.t('expense added!')}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(widget.ref.t('Add Expense'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: InputDecoration(labelText: widget.ref.t('Category'), prefixIcon: const Icon(LucideIcons.tag, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
          items: expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(widget.ref.t(c)))).toList(),
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 12),
        TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true,
          decoration: InputDecoration(labelText: '${widget.ref.t('Amount')} (₱)', prefixIcon: const Icon(LucideIcons.dollarSign, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) setState(() => _date = d.toIso8601String().substring(0, 10));
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [Icon(LucideIcons.calendar, size: 16, color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[500]), const SizedBox(width: 8), Text(_date)])),
        ),
        const SizedBox(height: 12),
        TextField(controller: _noteCtrl, textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: '${widget.ref.t('Note')} (${widget.ref.t('optional')})', prefixIcon: const Icon(LucideIcons.fileText, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          icon: const Icon(LucideIcons.plus),
          label: Text(widget.ref.t('Add Expense')),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _submit,
        )),
      ]),
    );
  }
}
