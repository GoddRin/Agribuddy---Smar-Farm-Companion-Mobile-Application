import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _editProfile(user) {
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.name);
    final userCtrl = TextEditingController(text: user.username);
    final farmCtrl = TextEditingController(text: user.farmName);

    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(ref.t('Edit Profile')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: ref.t('Full Name'))),
            const SizedBox(height: 10),
            TextField(controller: userCtrl, decoration: InputDecoration(labelText: ref.t('Username'))),
            const SizedBox(height: 10),
            TextField(controller: farmCtrl, decoration: InputDecoration(labelText: ref.t('Farm Name'))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ref.t('Cancel'))),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).updateProfile(
                name: nameCtrl.text, username: userCtrl.text, farmName: farmCtrl.text,
              );
              Navigator.pop(ctx);
            },
            child: Text(ref.t('Save')),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(ref.t('Settings'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Profile info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(LucideIcons.user, size: 18),
              const SizedBox(width: 10),
              Text(ref.t('Account'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.edit3, size: 16),
                onPressed: () => _editProfile(user),
              ),
            ]),
            const Divider(height: 24),
            _infoRow(ref.t('Full Name'), user?.name ?? '—'),
            const SizedBox(height: 8),
            _infoRow(ref.t('Username'), '@${user?.username ?? '—'}'),
            const SizedBox(height: 8),
            _infoRow(ref.t('Farm Name'), user?.farmName ?? '—'),
          ]),
        ).animate().fadeIn().slideY(begin: -0.1),
        const SizedBox(height: 16),

        // Preferences
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(LucideIcons.settings, size: 18),
              const SizedBox(width: 10),
              Text(ref.t('Settings'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 24),
            
            // Language Toggle
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(ref.t('Language'), style: const TextStyle(fontWeight: FontWeight.w500)),
              DropdownButton<String>(
                value: settings['language'],
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(ref.t('English'), style: const TextStyle(fontSize: 14))),
                  DropdownMenuItem(value: 'tl', child: Text(ref.t('Filipino (Tagalog)'), style: const TextStyle(fontSize: 14))),
                ],
                onChanged: (v) {
                  if (v != null) ref.read(settingsProvider.notifier).setLanguage(v);
                },
              ),
            ]),
          ]),
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 16),

        const SizedBox(height: 16),

        // Developer Credit
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(LucideIcons.code, size: 18), const SizedBox(width: 10), Text(ref.t('Developer'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
            const Divider(height: 20),
            const Text('Made/Developed by:\nMarc Harrold Salva', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, height: 1.5)),
          ]),
        ).animate().fadeIn(delay: 100.ms),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Row(
    children: [
      Text('$label:', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ],
  );
}
