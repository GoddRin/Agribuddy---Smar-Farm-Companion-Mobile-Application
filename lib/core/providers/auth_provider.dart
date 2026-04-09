import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hive/hive_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  const AuthState({required this.status, this.user, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  void _init() {
    final user = HiveService.currentUser;
    if (user != null) {
      debugPrint("Auth Init: User recognized -> ${user.username}");
    } else {
      debugPrint("Auth Init: No active session found.");
    }
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
      name: name.trim(),
      username: username.toLowerCase().trim(),
      farmName: farmName.trim(),
      email: cur.email,
      password: cur.password,
      googleId: cur.googleId,
      phoneNumber: cur.phoneNumber,
    );
    await HiveService.saveUser(updated);
    await HiveService.saveSession(updated);
    state = AuthState(status: AuthStatus.authenticated, user: updated);
  }

  Future<void> logout() async {
    try {
      await _ref.read(authServiceProvider).signOut();
      await HiveService.clearSession();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
