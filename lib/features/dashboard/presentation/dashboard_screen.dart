import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/crop_provider.dart';
import '../../../core/providers/logs_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/expenses_provider.dart';
import '../../../core/providers/connectivity_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(int h) {
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Map<String, String> _timeBasedTrivia(int h) {
    if (h >= 5 && h < 9) {
      return {'emoji': '🌅', 'title': 'Morning Dew', 'body': 'Magandang mag-spray ng abono habang malamig pa ang araw para madaling ma-absorb.'};
    } else if (h >= 9 && h < 14) {
      return {'emoji': '☀️', 'title': 'Peak Sun', 'body': 'Iwasang magdilig sa tanghali para hindi mabilis mag-evaporate ang tubig.'};
    } else if (h >= 14 && h < 18) {
      return {'emoji': '⛅', 'title': 'Afternoon Check', 'body': 'Mainam na tignan kung may mga bagong peste na umaatake sa crops ngayong hapon.'};
    } else {
      return {'emoji': '🌙', 'title': 'Night Rest', 'body': 'Magplanong mabuti ng mga gagawin at balikan ang records para bukas.'};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final crops = ref.watch(cropProvider);
    final logs = ref.watch(logsProvider);
    final tasks = ref.watch(tasksProvider);

    // Philippine Time is UTC+8
    final phTime = DateTime.now().toUtc().add(const Duration(hours: 8));
    final phHour = phTime.hour;

    final tip = _timeBasedTrivia(phHour);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final todayTasks = ref.read(tasksProvider.notifier).todayTasks;
    final overdueTasks = ref.read(tasksProvider.notifier).overdueTasks;
    final weekLogs = ref.read(logsProvider.notifier).thisWeekLogs;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF030D08), const Color(0xFF047857).withValues(alpha: 0.15), const Color(0xFF0A0F0D)]
                : [const Color(0xFFE8F5E9), const Color(0xFFF0FFF4), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Header
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${ref.t(_greeting(phHour))}, ${user?.name.split(' ').first ?? 'Farmer'}! 👋',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ).animate().fadeIn().slideY(begin: -0.2),
                        if (user?.farmName != null)
                          Text(user!.farmName, style: TextStyle(color: Colors.grey[500], fontSize: 13))
                              .animate().fadeIn(delay: 100.ms),
                      ],
                    )),
                    _themeButton(context, ref),
                    const SizedBox(width: 8),
                    _syncIndicator(context, ref),
                    const SizedBox(width: 8),
                    _bellButton(context, ref),
                  ],
                ),
              )),

              // ── Alert banner (overdue)
              if (overdueTasks.isNotEmpty)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => context.go('/home/tasks'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 18),
                        const SizedBox(width: 10),
                        Text('${overdueTasks.length} ${ref.t('Overdue!')}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Text('View →', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ]),
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1),
                )),



              // ── Stat cards
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  _statCard(context, ref, icon: LucideIcons.sprout, label: ref.t('Crops'), value: '${crops.length}', color: Colors.green, delay: 0),
                  const SizedBox(width: 12),
                  _statCard(context, ref, icon: LucideIcons.clipboardList, label: ref.t('Logs'), value: '${weekLogs.length}', color: Colors.teal, delay: 80),
                  const SizedBox(width: 12),
                  _statCard(context, ref, icon: LucideIcons.checkSquare, label: ref.t('Tasks'), value: '${tasks.where((t) => !t.isCompleted).length}', color: Colors.orange, delay: 160),
                ]),
              )),

              // ── Tip of the Day
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _tipCard(tip, ref),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1)),

              // ── Today's Tasks
              if (todayTasks.isNotEmpty)
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(ref.t("Tasks"), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(onPressed: () => context.go('/home/tasks'), child: const Text('All →')),
                      ]),
                      ...todayTasks.take(3).map((t) => _taskTile(context, t, theme)),
                    ],
                  ).animate().fadeIn(delay: 250.ms),
                )),

              // ── Recent Logs
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(ref.t('Logs'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(onPressed: () => context.go('/home/logs'), child: const Text('All →')),
                    ]),
                    if (logs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(LucideIcons.clipboardList, color: Colors.grey[400]),
                          const SizedBox(width: 10),
                          Text('No logs yet.', style: TextStyle(color: Colors.grey[400])),
                        ]),
                      )
                    else
                      ...logs.take(2).map((l) => _logTile(l, theme)),
                  ],
                ).animate().fadeIn(delay: 300.ms),
              )),

              // ── Quick Actions
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.t('Quick Actions'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16, mainAxisSpacing: 16,
                      childAspectRatio: 1.65,
                      children: [
                        _actionCard(context, LucideIcons.coins, ref.t('Expense Tracker'), 'Finance', Colors.blue, '/expenses'),
                        _actionCard(context, LucideIcons.messageSquare, ref.t('Mang Pedro'), 'AI Assistant', Colors.green, '/chat'),
                        _actionCard(context, LucideIcons.barChart2, ref.t('Reports'), 'Analytics', Colors.purple, '/reports'),
                        _actionCard(context, LucideIcons.calendar, ref.t('Farm Calendar'), 'Schedule', Colors.orange, '/calendar'),
                        _actionCard(context, LucideIcons.settings, ref.t('Account Settings'), 'Profile', Colors.teal, '/profile'),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 350.ms),
              )),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bellButton(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropProvider);
    final tasks = ref.watch(tasksProvider);

    // Build smart notifications from live farm data
    final List<_FarmNotif> notifs = [];
    for (final c in crops) {
      if (c.health < 0.4) {
        notifs.add(_FarmNotif('🚨', 'Critical: ${c.name}',
            'Health at ${(c.health * 100).toStringAsFixed(0)}% — needs immediate attention!', Colors.red));
      } else if (c.health < 0.65) {
        notifs.add(_FarmNotif('⚠️', 'Low Health: ${c.name}',
            'Health is ${(c.health * 100).toStringAsFixed(0)}%. Consider fertilizing.', Colors.orange));
      }
      final harvestStr = c.daysUntilHarvest;
      if (harvestStr != null) {
        if (harvestStr == 'Overdue' || harvestStr == 'Today!') {
          notifs.add(_FarmNotif('🌾', 'Ready to Harvest!',
              '${c.name} sa ${c.block} ay pwede nang anihin!', Colors.green));
        } else {
          final daysNum = int.tryParse(harvestStr.replaceAll(' days', '').trim());
          if (daysNum != null && daysNum <= 3) {
            notifs.add(_FarmNotif('📅', 'Harvest Soon: ${c.name}',
                '$daysNum day${daysNum == 1 ? '' : 's'} na lang bago i-harvest si ${c.name}.', Colors.amber));
          }
        }
      }
    }
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    if (pendingTasks > 0) {
      notifs.add(_FarmNotif('✅', '$pendingTasks Pending Task${pendingTasks > 1 ? 's' : ''}',
          'Mayroon kang $pendingTasks na hindi pa tapos na gawain ngayon.', Colors.blue));
    }
    if (notifs.isEmpty) {
      final h = DateTime.now().toUtc().add(const Duration(hours: 8)).hour;
      final tip = h < 9
          ? 'Great time to water crops — cool morning air reduces evaporation.'
          : h < 14
              ? 'Check your crops for pests — insects are most active midday.'
              : h < 18
                  ? 'Afternoon is ideal for harvesting — sugar content is highest.'
                  : 'Plan tomorrow\'s tasks tonight for a productive farm day!';
      notifs.add(_FarmNotif('💡', 'Farm Tip', tip, Colors.teal));
    }

    final hasAlert = notifs.any((n) => n.color == Colors.red || n.color == Colors.orange);

    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: IconButton(
          icon: const Icon(LucideIcons.bell),
          onPressed: () => _showNotifPanel(context, notifs),
        ),
      ),
      if (hasAlert)
        Positioned(
          right: 6, top: 6,
          child: Container(
            width: 9, height: 9,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 700.ms),
        ),
    ]).animate().fadeIn().scale();
  }

  void _showNotifPanel(BuildContext context, List<_FarmNotif> notifs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (ctx, sc) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(children: [
                const Icon(LucideIcons.bell, size: 20),
                const SizedBox(width: 10),
                Text('Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${notifs.length} new',
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: sc,
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: notifs.length,
                itemBuilder: (ctx2, i) => _NotifCard(notif: notifs[i])
                  .animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideX(begin: 0.06),
              ),
            ),
          ]),
        ),
      ),
    );
  }


  Widget _themeButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: IconButton(
        icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, color: isDark ? Colors.orange : Colors.indigo),
        onPressed: () {
          ref.read(settingsProvider.notifier).toggleDarkMode(!isDark);
        },
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }

  Widget _syncIndicator(BuildContext context, WidgetRef ref) {
    final hasUnsyncedLogs = ref.watch(logsProvider.notifier).hasUnsynced;
    final hasUnsyncedTasks = ref.watch(tasksProvider.notifier).hasUnsynced;
    final hasUnsyncedExpenses = ref.watch(expensesProvider.notifier).hasUnsynced;
    final connectivity = ref.watch(connectivityProvider);
    
    final hasUnsynced = hasUnsyncedLogs || hasUnsyncedTasks || hasUnsyncedExpenses;
    final isOnline = connectivity == ConnectivityStatus.isConnected;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color iconColor;
    IconData iconData;
    String tooltipMsg;
    String snackMsg;

    if (!isOnline) {
      iconColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;
      iconData = LucideIcons.cloudOff; 
      tooltipMsg = ref.t('Offline - Sync paused');
      snackMsg = ref.t('You are in offline mode. Syncing will resume when online.');
    } else if (hasUnsynced) {
      iconColor = Colors.orange;
      iconData = LucideIcons.uploadCloud; 
      tooltipMsg = ref.t('Local data ready to sync');
      snackMsg = ref.t('You are online. Your data is being queued for cloud sync.');
    } else {
      iconColor = Colors.green;
      iconData = LucideIcons.cloud;
      tooltipMsg = ref.t('All data synced');
      snackMsg = ref.t('Your farm data is securely backed up in the cloud.');
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Tooltip(
        message: tooltipMsg,
        child: Stack(alignment: Alignment.center, children: [
          IconButton(
            icon: Icon(iconData, color: iconColor, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(snackMsg),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          if (hasUnsynced && isOnline) 
            Positioned(top: 12, right: 12, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))),
        ]),
      ),
    ).animate().fadeIn(delay: 150.ms).scale();
  }

  Widget _statCard(BuildContext context, WidgetRef ref, {required IconData icon, required String label, required String value, required Color color, required int delay}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.1), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.2, curve: Curves.easeOutQuad),
    );
  }

  Widget _tipCard(Map<String, String> tip, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tip['emoji']!, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ref.t('Tip of the Day'), style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(tip['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(tip['body']!, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _taskTile(BuildContext context, task, ThemeData theme) {
    final color = _catColor(task.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text('${task.dueTime}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    );
  }

  Widget _logTile(log, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(LucideIcons.leaf, color: Color(0xFF16A34A), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${log.date} ${log.time}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(log.type, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String label, String sub, Color color, String route) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.2)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Irrigation': return Colors.blue;
      case 'Fertilizer': return Colors.green;
      case 'Spraying': return Colors.orange;
      case 'Harvesting': return Colors.amber;
      default: return Colors.grey;
    }
  }
}

// ─── Notification Model ────────────────────────────────────
class _FarmNotif {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  const _FarmNotif(this.emoji, this.title, this.body, this.color);
}

// ─── Notification Card Widget ──────────────────────────────
class _NotifCard extends StatelessWidget {
  final _FarmNotif notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notif.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: notif.color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: notif.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(notif.emoji, style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notif.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: notif.color,
            )),
          const SizedBox(height: 4),
          Text(notif.body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75),
              height: 1.5,
            )),
        ])),
      ]),
    );
  }
}
