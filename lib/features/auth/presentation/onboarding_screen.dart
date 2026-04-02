import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/hive/hive_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      emoji: '🌱',
      title: 'Track Your Crops',
      subtitle: 'Manage every crop from seedling to harvest. Monitor health, stages, and expected harvest dates.',
      color: Color(0xFF16A34A),
    ),
    _OnboardPage(
      emoji: '📋',
      title: 'Log Daily Activities',
      subtitle: 'Record every farm activity — with exact date and time, notes, and photos. Nothing slips through.',
      color: Color(0xFF0284C7),
    ),
    _OnboardPage(
      emoji: '🧑‍🌾',
      title: 'AI-Powered Advice',
      subtitle: 'Ask Mang Pedro anything about your farm. Get smart recommendations powered by Gemini AI.',
      color: Color(0xFF7C3AED),
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() async {
    await HiveService.setOnboardingDone();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [page.color.withValues(alpha: 0.08), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(_pages.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i ? page.color : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: Text('Skip', style: TextStyle(color: Colors.grey[500])),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(p.emoji, style: const TextStyle(fontSize: 80)),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 48),
                          Text(
                            p.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: p.color,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                          const SizedBox(height: 16),
                          Text(
                            p.subtitle,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.6),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _next,
                    child: Text(
                      _page == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String emoji, title, subtitle;
  final Color color;
  const _OnboardPage({required this.emoji, required this.title, required this.subtitle, required this.color});
}
