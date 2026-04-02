import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _farmCtrl     = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _emailCtrl.dispose();
    _farmCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      // Intentionally hardcoding this error string or we can add to appLoc later
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).register(
      name: _nameCtrl.text,
      username: _usernameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      farmName: _farmCtrl.text,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3), blurRadius: 20)],
                  ),
                  child: const Center(child: Text('🌱', style: TextStyle(fontSize: 34))),
                ).animate().scale(curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(ref.t('Create Account'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))
                    .animate().fadeIn(delay: 100.ms),
                Text(ref.t('Set up your farm profile'), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]))
                    .animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 28),

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
                        const SizedBox(height: 14),
                      ],

                      _field(_nameCtrl, ref.t('Full Name'), LucideIcons.user, isDark,
                          cap: TextCapitalization.words,
                          v: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your name' : null),
                      const SizedBox(height: 12),

                      // Username field — highlighted
                      TextFormField(
                        controller: _usernameCtrl,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: ref.t('Username'),
                          hintText: 'e.g. juan_dela_cruz',
                          helperText: 'Used to log in. No spaces allowed.',
                          labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                          prefixIcon: Icon(LucideIcons.atSign, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5),
                          ),
                          filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Choose a username';
                          if (v.contains(' ')) return 'No spaces allowed in username';
                          if (v.trim().length < 3) return 'Username must be at least 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _field(_emailCtrl, ref.t('Email (optional)'), LucideIcons.mail, isDark,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 12),

                      _field(_farmCtrl, ref.t('Farm Name'), LucideIcons.sprout, isDark,
                          cap: TextCapitalization.words,
                          v: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your farm name' : null),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _deco(ref.t('Password'), LucideIcons.lock, isDark).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: isDark ? Colors.grey[400] : null),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v?.length ?? 0) < 6 ? 'At least 6 characters' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: _deco(ref.t('Confirm Password'), LucideIcons.lock, isDark),
                        validator: (v) => (v?.isEmpty ?? true) ? 'Confirm your password' : null,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(ref.t('Create Account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(ref.t('Sign In'), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ]).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, bool isDark,
      {TextCapitalization cap = TextCapitalization.none,
       TextInputType? keyboard,
       String? Function(String?)? v}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        textCapitalization: cap,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: _deco(label, icon, isDark),
        validator: v,
      );

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
