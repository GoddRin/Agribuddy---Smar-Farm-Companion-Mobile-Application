import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/hive/hive_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/services/audio_service.dart';
import 'core/services/tts_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  await HiveService.init();
  runApp(const ProviderScope(child: SmartFarmApp()));
}

class SmartFarmApp extends ConsumerStatefulWidget {
  const SmartFarmApp({super.key});

  @override
  ConsumerState<SmartFarmApp> createState() => _SmartFarmAppState();
}

class _SmartFarmAppState extends ConsumerState<SmartFarmApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = ref.read(audioServiceProvider);
    final tts = ref.read(ttsServiceProvider);
    final isMusicEnabled = ref.read(settingsProvider.notifier).isMusicEnabled;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.inactive) {
      // Stop ALL sounds when leaving the app
      audio.stopBgm();
      tts.stop();
    } else if (state == AppLifecycleState.resumed) {
      // Resume background music only if the user has it enabled
      if (isMusicEnabled) {
        audio.startBgm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = settings['isDarkMode'] == 'true';

    return MaterialApp.router(
      title: 'AgriBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Desktop Simulator Mode
            if (constraints.maxWidth > 600) {
              return Container(
                color: const Color(0xFF16A34A).withValues(alpha: 0.05), // Subtle farm background
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1024),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 50,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ClipRect(child: child!),
                    ),
                  ),
                ),
              );
            }
            
            // Mobile (Native) Mode
            return child!;
          },
        );
      },
    );
  }
}
