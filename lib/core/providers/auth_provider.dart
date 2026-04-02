import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';
import '../models/user_model.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  const AuthState({required this.status, this.user, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  void _init() {
    final user = HiveService.currentUser;
    state = AuthState(
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: user,
    );
  }

  Future<String?> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String farmName,
  }) async {
    final cleanUsername = username.toLowerCase().trim();
    if (cleanUsername.isEmpty) return 'Username cannot be empty.';
    if (cleanUsername.contains(' ')) return 'Username cannot contain spaces.';

    final existing = HiveService.getUserByUsername(cleanUsername);
    if (existing != null) return 'Username "$username" is already taken.';

    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      username: cleanUsername,
      email: email.toLowerCase().trim(),
      password: password,
      farmName: farmName.trim(),
    );
    await HiveService.saveUser(user);
    await HiveService.saveSession(user);
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return null; // null = success
  }

  Future<String?> login(String username, String password) async {
    final user = HiveService.getUserByUsername(username.trim());
    if (user == null) return 'No account found with username "@$username".';
    if (user.password != password) return 'Incorrect password.';
    await HiveService.saveSession(user);
    state = AuthState(status: AuthStatus.authenticated, user: user);
    return null;
  }

  Future<void> updateProfile({required String name, required String username, required String farmName}) async {
    final cur = state.user;
    if (cur == null) return;
    final updated = UserModel(
      id: cur.id,
      password: cur.password,
      email: cur.email,
      name: name.trim(),
      username: username.toLowerCase().trim(),
      farmName: farmName.trim(),
    );
    await HiveService.saveUser(updated);
    await HiveService.saveSession(updated);
    state = AuthState(status: AuthStatus.authenticated, user: updated);
  }

  Future<void> logout() async {
    await HiveService.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
