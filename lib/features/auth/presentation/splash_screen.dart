import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/hive/hive_service.dart';
import '../../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _leafCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    _leafCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3200), _navigate);
  }

  @override
  void dispose() {
    _leafCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go('/home/dashboard');
    } else if (HiveService.onboardingDone) {
      context.go('/login');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF052E16), Color(0xFF0D4A23), Color(0xFF16A34A)],
          ),
        ),
        child: Stack(
          children: [
            // ── Floating leaf particles
            ..._buildLeafParticles(),

            // ── Subtle grid texture overlay
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),

            // ── Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo mark
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(
                                alpha: 0.25 + _pulseCtrl.value * 0.35,
                              ),
                              blurRadius: 28 + _pulseCtrl.value * 20,
                              spreadRadius: 4 + _pulseCtrl.value * 6,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: child,
                      ),
                      child: const Center(
                        child: Text('🌾', style: TextStyle(fontSize: 58)),
                      ),
                    )
                        .animate()
                        .scale(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(),

                    const SizedBox(height: 32),

                    // ── "Agri" word
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Agri',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Buddy',
                            style: TextStyle(
                              color: Color(0xFF86EFAC),
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 400))
                        .slideY(begin: 0.3, curve: Curves.easeOut),

                    const SizedBox(height: 8),

                    // ── Tagline
                    const Text(
                      'Ang Smart Farm Assistant Mo',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 700)),

                    const SizedBox(height: 10),

                    // ── Divider line
                    Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.transparent, Color(0xFF86EFAC), Colors.transparent],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ).animate().fadeIn(delay: const Duration(milliseconds: 900)),

                    const SizedBox(height: 64),

                    // ── Loading indicator
                    Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: const Color(0xFF86EFAC).withValues(alpha: 0.8),
                            strokeWidth: 2.5,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ).animate().fadeIn(delay: const Duration(milliseconds: 1100)),
                        const SizedBox(height: 12),
                        const Text(
                          'Inihahanda ng iyong bukid...',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ).animate().fadeIn(delay: const Duration(milliseconds: 1300)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLeafParticles() {
    final rng = Random(42);
    return List.generate(14, (i) {
      final x = rng.nextDouble();
      final y = rng.nextDouble();
      final size = 8.0 + rng.nextDouble() * 14;
      final delay = rng.nextDouble() * 2.0;
      final duration = 3.0 + rng.nextDouble() * 3.0;
      final emojis = ['🌱', '🍃', '🌿', '🌾', '🍀'];
      final emoji = emojis[i % emojis.length];

      return Positioned(
        left: MediaQuery.sizeOf(context).width * x,
        top: MediaQuery.sizeOf(context).height * y,
        child: AnimatedBuilder(
          animation: _leafCtrl,
          builder: (_, child) {
            final t = (_leafCtrl.value + delay / duration) % 1.0;
            return Transform.translate(
              offset: Offset(
                sin(t * 2 * pi) * 12,
                -t * 80,
              ),
              child: Opacity(
                opacity: (sin(t * pi)).clamp(0.0, 1.0) * 0.4,
                child: child,
              ),
            );
          },
          child: Text(emoji, style: TextStyle(fontSize: size)),
        ),
      );
    });
  }
}

// ── Subtle grid overlay painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.8;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
