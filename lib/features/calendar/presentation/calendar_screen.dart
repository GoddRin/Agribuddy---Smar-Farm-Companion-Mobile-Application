import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/crop_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../tasks/presentation/widgets/add_task_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final logs = ref.watch(logsProvider);
    final crops = ref.watch(cropProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build event map: date string → list of events
    final events = <String, List<_CalEvent>>{};
    void add(String date, _CalEvent e) => (events[date] ??= []).add(e);

    for (final t in tasks) {
      add(t.dueDate, _CalEvent(t.title, t.isCompleted ? Colors.grey : _tCatColor(t.category), LucideIcons.checkSquare));
    }
    for (final l in logs) {
      add(l.date, _CalEvent(l.title, Colors.teal, LucideIcons.clipboardList));
    }
    for (final c in crops) {
      if (c.expectedHarvestDate != null) add(c.expectedHarvestDate!, _CalEvent('${ref.t('Harvest')}: ${c.name}', Colors.amber, LucideIcons.scissors));
    }

    final sel = _selected;
    final selKey = sel == null ? '' : '${sel.year}-${sel.month.toString().padLeft(2,'0')}-${sel.day.toString().padLeft(2,'0')}';
    final selEvents = events[selKey] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(ref.t('Farm Calendar'))),
      body: Column(children: [
        // Month nav
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
          IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.primary), 
            onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1))
          ),
          Expanded(child: Column(
            children: [
              Text(ref.t(_monthName(_focused.month)), 
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(_focused.year.toString(), style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )),
          IconButton(
            icon: Icon(LucideIcons.chevronRight, color: theme.colorScheme.primary), 
            onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1))
          ),
        ])),

        // Day labels
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map((d) =>
          Expanded(child: Center(child: Text(ref.t(d).toUpperCase(), 
            style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w900, letterSpacing: 1))))).toList())),

        // Calendar grid
        _buildGrid(events, theme),

        const Divider(height: 32, thickness: 1, indent: 20, endIndent: 20),

        // Selected day events
        if (sel != null) ...[
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${ref.t(_dayName(sel.weekday))}, ${sel.day} ${ref.t(_monthName(sel.month))}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
              Text('${selEvents.length} ${ref.t(selEvents.length != 1 ? 'events scheduled' : 'event scheduled')}', 
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            IconButton.filledTonal(
              icon: const Icon(LucideIcons.plus, size: 20),
              onPressed: () => _openAddSheet(context, ref, sel),
              tooltip: ref.t('Add Event'),
            ),
          ])),
          Expanded(child: selEvents.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.calendarX2, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(ref.t('No events for this day'), style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  ],
                ))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final e = selEvents[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color, 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border(left: BorderSide(color: e.color, width: 4))
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: e.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(e.icon, color: e.color, size: 16),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey[300]),
                      ]),
                    );
                  },
                )),
        ] else
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.calendarSearch, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(ref.t('Tap a date to manage schedule'), style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
          ]))),
      ]),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        onPressed: () => _openAddSheet(context, ref, _selected ?? DateTime.now()),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(LucideIcons.calendarPlus, color: Colors.white),
      ),
    );
  }

  Widget _buildGrid(Map<String, List<_CalEvent>> events, ThemeData theme) {
    final first = DateTime(_focused.year, _focused.month, 1);
    final lastDay = DateTime(_focused.year, _focused.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // 0=Sun
    final todayState = DateTime.now();
    final isDark = theme.brightness == Brightness.dark;

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(_focused.year, _focused.month, d);
      final key = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final evts = events[key] ?? [];
      final isToday = date.year == todayState.year && date.month == todayState.month && date.day == todayState.day;
      final isSel = _selected != null && _selected!.year == date.year && _selected!.month == date.month && _selected!.day == date.day;

      cells.add(GestureDetector(
        onTap: () => setState(() => _selected = date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSel ? theme.colorScheme.primary : isToday ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isSel ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 1) : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$d', style: TextStyle(
                    fontSize: 14, fontWeight: isToday || isSel ? FontWeight.w900 : FontWeight.w500,
                    color: isSel ? Colors.white : isToday ? theme.colorScheme.primary : (isDark ? Colors.grey[300] : Colors.black87),
                  )),
                  if (evts.isNotEmpty) const SizedBox(height: 2),
                  if (evts.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.center, children: evts.take(3).map((e) =>
                    Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: isSel ? Colors.white70 : e.color, shape: BoxShape.circle))).toList()),
                ]),
              ),
              if (isToday) Positioned(top: 4, right: 4, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ],
          ),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cells),
    );
  }

  void _openAddSheet(BuildContext ctx, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddTaskSheet(ref: ref, initialDate: date),
    );
  }

  Color _tCatColor(String cat) {
    switch (cat) {
      case 'Irrigation': return Colors.blue;
      case 'Fertilizer': return Colors.green;
      case 'Spraying': return Colors.orange;
      case 'Harvesting': return Colors.amber;
      default: return Colors.grey;
    }
  }

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
  String _dayName(int d) => const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d - 1];
}

class _CalEvent {
  final String label;
  final Color color;
  final IconData icon;
  const _CalEvent(this.label, this.color, this.icon);
}
