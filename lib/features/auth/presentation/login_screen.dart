import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _usernameCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).login(
      _usernameCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() { _error = err; _loading = false; });
    } else {
      context.go('/home/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF020617)] 
              : [const Color(0xFFE8F5E9), const Color(0xFFF0FFF4), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: const Center(child: Text('🌾', style: TextStyle(fontSize: 42))),
                  ).animate().scale(curve: Curves.elasticOut),
                  const SizedBox(height: 22),
                  Text(ref.t('Welcome Back'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                      .animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Text(ref.t('Sign in to your farm account'), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]))
                      .animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 36),

                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        // Error banner
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              const Icon(LucideIcons.alertCircle, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Username field
                        TextFormField(
                          controller: _usernameCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: _deco(ref.t('Username'), LucideIcons.atSign, isDark),
                          validator: (v) => (v?.trim().isEmpty ?? true) ? ref.t('Enter your username') : null,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          onFieldSubmitted: (_) => _login(),
                          decoration: _deco(ref.t('Password'), LucideIcons.lock, isDark).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: isDark ? Colors.grey[400] : null),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? ref.t('Enter your password') : null,
                        ),
                        const SizedBox(height: 24),

                        // Sign In button
                        SizedBox(
                          width: double.infinity, height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(ref.t('Sign In'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(ref.t("Don't have an account? "), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(ref.t('Register'), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ]).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon, bool isDark) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
    prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!)),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
  );
}
