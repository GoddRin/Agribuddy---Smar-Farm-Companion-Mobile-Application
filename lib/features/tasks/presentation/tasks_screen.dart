import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/task_item.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/audio_service.dart';
import 'widgets/add_task_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    final theme = Theme.of(context);

    final today    = notifier.todayTasks;
    final overdue  = notifier.overdueTasks;
    final upcoming = tasks.where((t) => !t.isCompleted && !t.isDueToday && !t.isOverdue).toList();
    final done     = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('Task Planner')),
        bottom: TabBar(controller: _tab, tabs: [Tab(text: ref.t('Upcoming')), Tab(text: ref.t('Today')), Tab(text: ref.t('Done'))]),
      ),
      body: TabBarView(controller: _tab, children: [
        _taskList(context, [...overdue, ...upcoming], ref, showOverdue: true),
        _taskList(context, today, ref),
        _taskList(context, done, ref, isDone: true),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context, ref),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _taskList(BuildContext context, List<TaskItem> tasks, WidgetRef ref, {bool showOverdue = false, bool isDone = false}) {
    if (tasks.isEmpty) {
      return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isDone ? LucideIcons.checkCircle2 : LucideIcons.clipboardCheck, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(isDone ? ref.t('No completed tasks yet') : ref.t('No tasks here'), style: TextStyle(color: Colors.grey[500])),
      ]),
    );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        return _TaskCard(task: task, showOverdueBadge: showOverdue && task.isOverdue)
            .animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1);
      },
    );
  }

  static void _openAddSheet(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddTaskSheet(ref: ref),
    );
  }
}

// ─── Task Card ─────────────────────────────────────────────
class _TaskCard extends ConsumerWidget {
  final TaskItem task;
  final bool showOverdueBadge;
  const _TaskCard({required this.task, this.showOverdueBadge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catColor = _catColor(task.category);
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(tasksProvider.notifier).deleteTask(task.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: task.isOverdue ? Border.all(color: Colors.red.withValues(alpha: 0.4)) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
              onTap: () {
                ref.read(tasksProvider.notifier).toggleComplete(task.id);
                if (!task.isCompleted) {
                  ref.read(audioServiceProvider).playSfx(SfxType.success);
                }
              },
            child: Container(
              width: 32, height: 32, margin: const EdgeInsets.only(top: 2, right: 4),
              decoration: BoxDecoration(
                color: task.isCompleted ? catColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: task.isCompleted ? catColor : Colors.grey[400]!, width: 2.5),
              ),
              child: task.isCompleted ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(task.title,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: task.isCompleted ? Colors.grey : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87)))),
              if (showOverdueBadge) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                child: Text(ref.t('Overdue'), style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w900)),
              ) else Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: catColor.withValues(alpha: 0.3))),
                child: Text(ref.t(task.category), style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(LucideIcons.calendar, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(task.dueDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(width: 10),
              Icon(LucideIcons.clock, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(task.dueTime, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              if (task.cropName != null) ...[
                const SizedBox(width: 10),
                Icon(LucideIcons.sprout, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(task.cropName!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Irrigation': return Colors.blue;
      case 'Fertilizer': return Colors.green;
      case 'Spraying':   return Colors.orange;
      case 'Harvesting': return Colors.amber;
      case 'Planting':   return Colors.teal;
      case 'Inspection': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
