import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, guest, authenticated }

class AuthState {
  const AuthState._(this.status, this.user);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.guest() : this._(AuthStatus.guest, null);
  const AuthState.authenticated(AppUser user) : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isLoggedIn => user != null;
  UserRole? get role => user?.role;
  bool get isCustomer => role == UserRole.customer;
  bool get isStaffOrAdmin => role?.isStaffOrAdmin ?? false;
  bool get isAdmin => role == UserRole.admin;
}

/// Current session: who is signed in and with which role. The role only decides what the
/// app shows; the API enforces permissions on every request (BR-078).
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.read(apiClientProvider).onUnauthorized = _onUnauthorized;
    Future.microtask(_restore);
    return const AuthState.unknown();
  }

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> _restore() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null) {
      state = const AuthState.guest();
      return;
    }
    try {
      state = AuthState.authenticated(await _service.me());
    } catch (_) {
      // Revoked/expired tokens are cleared; on a network error we fall back to guest browsing.
      await ref.read(tokenStorageProvider).clear();
      state = const AuthState.guest();
    }
  }

  Future<void> login(String email, String password) async => _start(await _service.login(email, password));

  Future<void> register({required String fullName, required String email, required String password, String? phoneNumber}) async =>
      _start(await _service.register(fullName: fullName, email: email, password: password, phoneNumber: phoneNumber));

  Future<void> changePassword(String current, String next) async => _start(await _service.changePassword(current, next));

  Future<void> updateProfile({required String fullName, String? phoneNumber}) async {
    state = AuthState.authenticated(await _service.updateProfile(fullName: fullName, phoneNumber: phoneNumber));
  }

  Future<void> logout() async {
    try {
      await _service.logout();
    } catch (_) {
      // The local session is cleared even if the server cannot be reached.
    }
    await _clear();
  }

  Future<void> _start(AuthResult result) async {
    await ref.read(tokenStorageProvider).write(result.accessToken);
    state = AuthState.authenticated(result.user);
  }

  void _onUnauthorized() {
    if (state.isLoggedIn) _clear();
  }

  Future<void> _clear() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState.guest();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
