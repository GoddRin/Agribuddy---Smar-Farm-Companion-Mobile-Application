import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/crop_provider.dart';
import '../../../core/localization/app_localizations.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final logs = ref.watch(logsProvider);
    final crops = ref.watch(cropProvider);
    final theme = Theme.of(context);

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
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
          IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1))),
          Expanded(child: Text('${ref.t(_monthName(_focused.month))} ${_focused.year}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(LucideIcons.chevronRight), onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1))),
        ])),

        // Day labels
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map((d) =>
          Expanded(child: Center(child: Text(ref.t(d), style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600))))).toList())),
        const SizedBox(height: 6),

        // Calendar grid
        _buildGrid(events, theme),

        const Divider(height: 24),

        // Selected day events
        if (sel != null) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Row(children: [
            Text('${ref.t(_dayName(sel.weekday))}, ${sel.day} ${ref.t(_monthName(sel.month))}',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${selEvents.length} ${ref.t(selEvents.length != 1 ? 'events' : 'event')}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ])),
          Expanded(child: selEvents.isEmpty
              ? Center(child: Text(ref.t('No events on this day'), style: TextStyle(color: Colors.grey[400])))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: selEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final e = selEvents[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: e.color, width: 4))),
                      child: Row(children: [Icon(e.icon, color: e.color, size: 16), const SizedBox(width: 10), Expanded(child: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w500)))]),
                    );
                  },
                )),
        ] else
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.calendar, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(ref.t('Tap a date to see events'), style: TextStyle(color: Colors.grey[400])),
          ]))),
      ]),
    );
  }

  Widget _buildGrid(Map<String, List<_CalEvent>> events, ThemeData theme) {
    final first = DateTime(_focused.year, _focused.month, 1);
    final lastDay = DateTime(_focused.year, _focused.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // 0=Sun
    final today = DateTime.now();

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= lastDay; d++) {
      final date = DateTime(_focused.year, _focused.month, d);
      final key = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final evts = events[key] ?? [];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSel = _selected != null && _selected!.year == date.year && _selected!.month == date.month && _selected!.day == date.day;

      cells.add(GestureDetector(
        onTap: () => setState(() => _selected = date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSel ? theme.colorScheme.primary : isToday ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
            shape: BoxShape.circle,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d', style: TextStyle(
              fontSize: 13, fontWeight: isToday || isSel ? FontWeight.bold : null,
              color: isSel ? Colors.white : isToday ? theme.colorScheme.primary : null,
            )),
            if (evts.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.center, children: evts.take(3).map((e) =>
              Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: isSel ? Colors.white70 : e.color, shape: BoxShape.circle))).toList()),
          ]),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cells),
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
  String _dayName(int d) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
}

class _CalEvent {
  final String label;
  final Color color;
  final IconData icon;
  const _CalEvent(this.label, this.color, this.icon);
}
