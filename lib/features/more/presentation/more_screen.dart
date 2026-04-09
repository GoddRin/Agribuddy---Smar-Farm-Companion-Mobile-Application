import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    final items = [
      _MoreItem(LucideIcons.calendar,      ref.t('Calendar'),        ref.t('Monthly farm schedule'), Colors.orange,  '/calendar'),
      _MoreItem(LucideIcons.dollarSign,     ref.t('Expense Tracker'), ref.t('Track all farm costs'),  Colors.blue,    '/expenses'),
      _MoreItem(LucideIcons.barChart2,      ref.t('Reports'),         ref.t('Analytics & summaries'), Colors.purple,  '/reports'),
      _MoreItem(LucideIcons.settings,       ref.t('Settings'),        ref.t('App preferences & themes'),Colors.grey,    '/settings'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(ref.t('More'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(child: Text(
                  (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'F',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? ref.t('Farmer'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                Text('@${user?.username ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(user?.farmName ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ])),
              IconButton(
                icon: const Icon(LucideIcons.edit3, color: Colors.white),
                onPressed: () => context.push('/profile'),
              ),
            ]),
          ).animate().fadeIn().slideY(begin: -0.1),
          const SizedBox(height: 20),

          Text(ref.t('Features'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[500])),
          const SizedBox(height: 10),

          ...items.asMap().entries.map((e) {
            final item = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => context.push(item.route),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: theme.cardTheme.color,
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(item.subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60)).slideX(begin: 0.05);
          }),

          const SizedBox(height: 16),
          Divider(color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]),
          const SizedBox(height: 8),

          ListTile(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Colors.red.withValues(alpha: 0.06),
            leading: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.logOut, color: Colors.red, size: 20),
            ),
            title: Text(ref.t('Sign Out'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String title, subtitle, route;
  final Color color;
  const _MoreItem(this.icon, this.title, this.subtitle, this.color, this.route);
}
