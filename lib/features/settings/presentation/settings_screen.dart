import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/tts_service.dart';

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

            const Divider(height: 24),

            // Sound Effects Toggle
            _toggleRow(
              ref.t('Sound Effects'), 
              LucideIcons.volume2, 
              settings['isSoundEnabled'] != 'false',
              (v) => ref.read(settingsProvider.notifier).toggleSound(v),
            ),

            const SizedBox(height: 12),

            // Background Music Toggle
            _toggleRow(
              ref.t('Background Music'), 
              LucideIcons.music, 
              settings['isMusicEnabled'] != 'false',
              (v) {
                ref.read(settingsProvider.notifier).toggleMusic(v);
                if (v) {
                  ref.read(audioServiceProvider).startBgm();
                } else {
                  ref.read(audioServiceProvider).stopBgm();
                }
              },
            ),

            const SizedBox(height: 12),

            // AI Voice Toggle
            _toggleRow(
              ref.t('AI Voice (TTS)'), 
              LucideIcons.mic, 
              settings['isTtsEnabled'] != 'false',
              (v) => ref.read(settingsProvider.notifier).toggleTts(v),
            ),
            
            if (settings['isTtsEnabled'] != 'false') ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => ref.read(ttsServiceProvider).speak("Testing AI voice. Kumusta ka, kabayan?"),
                  icon: const Icon(LucideIcons.volume1, size: 16, color: Color(0xFF16A34A)),
                  label: Text(ref.t('Test Voice'), style: const TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            
            const Divider(height: 32),
            Text(ref.t('Volume Levels'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            
            // Music Volume
            _volumeSlider(
              ref.t('Music'),
              LucideIcons.music,
              ref.watch(settingsProvider.notifier).musicVolume,
              (v) => ref.read(settingsProvider.notifier).setMusicVolume(v),
            ),
            
            // SFX Volume
            _volumeSlider(
              ref.t('SFX'),
              LucideIcons.volume2,
              ref.watch(settingsProvider.notifier).sfxVolume,
              (v) => ref.read(settingsProvider.notifier).setSfxVolume(v),
            ),
            
            // Voice Volume
            _volumeSlider(
              ref.t('Voice'),
              LucideIcons.mic,
              ref.watch(settingsProvider.notifier).voiceVolume,
              (v) => ref.read(settingsProvider.notifier).setVoiceVolume(v),
            ),
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

  Widget _toggleRow(String label, IconData icon, bool value, Function(bool) onChanged) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const Spacer(),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF16A34A),
      ),
    ],
  );

  Widget _volumeSlider(String label, IconData icon, double value, Function(double) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 10),
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF16A34A),
            inactiveColor: Colors.grey[200],
          ),
        ),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
