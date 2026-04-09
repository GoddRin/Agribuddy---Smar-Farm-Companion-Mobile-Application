import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/crop_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/providers/expenses_provider.dart';
import '../../../core/localization/app_localizations.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropProvider);
    final logs = ref.watch(logsProvider);
    final tasks = ref.watch(tasksProvider);
    ref.watch(expensesProvider);
    final theme = Theme.of(context);

    final done = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final rate = total == 0 ? 0.0 : done / total;

    final expNotifier = ref.read(expensesProvider.notifier);
    final catData = expNotifier.byCategory;
    final totalExpenses = expNotifier.totalAllTime;

    // Logs by type
    final logsByType = <String, int>{};
    for (final l in logs) {
      logsByType[l.type] = (logsByType[l.type] ?? 0) + 1;
    }

    final typeColors = {
      'Planting': Colors.green, 'Watering': Colors.blue, 'Fertilizing': Colors.orange,
      'Pest Control': Colors.red, 'Harvesting': Colors.amber, 'Observation': Colors.teal, 'Other': Colors.grey,
    };

    return Scaffold(
      appBar: AppBar(title: Text(ref.t('Reports & Analytics'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Productivity Score
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ref.t('Productivity Score'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Text('${(rate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              Text('$done ${ref.t('of')} $total ${ref.t('tasks completed')}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            SizedBox(width: 80, height: 80,
              child: CircularProgressIndicator(value: rate, strokeWidth: 8, color: Colors.white, backgroundColor: Colors.white24)),
          ]),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 16),

        // Summary row
        Row(children: [
          _summaryCard(theme, label: ref.t('Crops'), value: '${crops.length}', icon: LucideIcons.sprout, color: Colors.green),
          const SizedBox(width: 12),
          _summaryCard(theme, label: ref.t('Total Logs'), value: '${logs.length}', icon: LucideIcons.clipboardList, color: Colors.teal),
          const SizedBox(width: 12),
          _summaryCard(theme, label: ref.t('Spending'), value: '₱${totalExpenses.toStringAsFixed(0)}', icon: LucideIcons.coins, color: Colors.blue),
        ]).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 20),

        // Expense pie chart
        if (catData.isNotEmpty) ...[
          Text(ref.t('Expense Breakdown'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PieChart(PieChartData(
              sections: catData.entries.map((e) {
                final pct = totalExpenses == 0 ? 0.0 : e.value / totalExpenses;
                return PieChartSectionData(
                  value: e.value,
                  title: '${(pct * 100).toStringAsFixed(0)}%',
                  color: _catColor(e.key),
                  radius: 80,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                );
              }).toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 6,
            children: catData.keys.map((k) => Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _catColor(k), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(ref.t(k), style: TextStyle(fontSize: 12, color: theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800])),
            ])).toList()),
          const SizedBox(height: 20),
        ],

        // Activity by type
        if (logsByType.isNotEmpty) ...[
          Text(ref.t('Activity Summary'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...logsByType.entries.map((e) {
            final color = typeColors[e.key] ?? Colors.grey;
            final pct = logs.isEmpty ? 0.0 : e.value / logs.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(ref.t(e.key), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800])),
                  const Spacer(),
                  Text('${e.value}×', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: pct, backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6)),
              ]),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Crop health table
        if (crops.isNotEmpty) ...[
          Text(ref.t('Crop Overview'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...crops.map((c) {
            final hc = c.health >= 0.8 ? Colors.green : c.health >= 0.6 ? Colors.orange : Colors.red;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${c.block} · ${ref.t(c.stage)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  if (c.expectedHarvestDate != null) Text('${ref.t('Harvest')}: ${c.expectedHarvestDate!} (${c.daysUntilHarvest})', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ])),
                Text('${(c.health * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: hc)),
              ]),
            );
          }),
        ],
        const SizedBox(height: 80),
      ]),
    );
  }

  Widget _summaryCard(ThemeData theme, {required String label, required String value, required IconData icon, required Color color}) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ]),
    ));
  }

  Color _catColor(String cat) {
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
