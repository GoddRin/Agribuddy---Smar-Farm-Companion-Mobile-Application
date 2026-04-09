import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audio_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).startBgm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref; // Re-alias for convenience or use it directly
    final loc = GoRouterState.of(context).uri.path;
    int idx = 0;
    if (loc.startsWith('/home/crops'))  idx = 1;
    if (loc.startsWith('/home/tasks'))  idx = 2;
    if (loc.startsWith('/home/logs'))   idx = 3;
    if (loc.startsWith('/home/more'))   idx = 4;

    const primary = Color(0xFF16A34A);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: idx,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (i) {
            unawaited(ref.read(audioServiceProvider).playSfx(SfxType.tap));
            switch (i) {
              case 0: context.go('/home/dashboard'); break;
              case 1: context.go('/home/crops');     break;
              case 2: context.go('/home/tasks');     break;
              case 3: context.go('/home/logs');      break;
              case 4: context.go('/home/more');      break;
            }
          },
          backgroundColor: Theme.of(context).cardTheme.color,
          indicatorColor: primary.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.home),          selectedIcon: Icon(LucideIcons.home, color: primary),          label: 'Home'),
            NavigationDestination(icon: Icon(LucideIcons.sprout),         selectedIcon: Icon(LucideIcons.sprout, color: primary),         label: 'Crops'),
            NavigationDestination(icon: Icon(LucideIcons.checkSquare),    selectedIcon: Icon(LucideIcons.checkSquare, color: primary),    label: 'Tasks'),
            NavigationDestination(icon: Icon(LucideIcons.clipboardList),  selectedIcon: Icon(LucideIcons.clipboardList, color: primary),  label: 'Logs'),
            NavigationDestination(icon: Icon(LucideIcons.layoutGrid),     selectedIcon: Icon(LucideIcons.layoutGrid, color: primary),     label: 'More'),
          ],
        ),
      ),
    );
  }
}
