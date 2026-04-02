import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _farmCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _userCtrl = TextEditingController(text: user?.username ?? '');
    _farmCtrl = TextEditingController(text: user?.farmName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _farmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await ref.read(authProvider.notifier).updateProfile(
      name: _nameCtrl.text,
      username: _userCtrl.text,
      farmName: _farmCtrl.text,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(LucideIcons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Full Name'),
              _input(_nameCtrl, LucideIcons.user, isDark),
              const SizedBox(height: 20),
              
              _label('Username'),
              _input(_userCtrl, LucideIcons.atSign, isDark),
              const SizedBox(height: 20),
              
              _label('Farm Name'),
              _input(_farmCtrl, LucideIcons.sprout, isDark),
              const SizedBox(height: 40),
              
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
  );

  Widget _input(TextEditingController ctrl, IconData icon, bool isDark) => TextFormField(
    controller: ctrl,
    style: TextStyle(color: isDark ? Colors.white : Colors.black),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, size: 18, color: Colors.green),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
  );
}
