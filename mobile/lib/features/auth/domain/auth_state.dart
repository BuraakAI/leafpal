import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/secure_storage.dart';

class AuthUser {
  final String id;
  final String email;
  final String? name;
  const AuthUser({required this.id, required this.email, this.name});
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial());

  Future<bool> checkAuth() async {
    final token = await AppStorage.instance.read(key: 'auth_token');
    if (token != null) return true;
    state = const AuthUnauthenticated();
    return false;
  }

  // Gerçek API login/register sonrası çağrılır
  void setUser({required String id, required String email, String? name}) {
    state = AuthAuthenticated(AuthUser(id: id, email: email, name: name));
  }

  Future<void> loginDev() async {
    await AppStorage.instance.write(key: 'auth_token', value: 'dev-token');
    state = const AuthAuthenticated(
      AuthUser(id: 'dev-user-id', email: 'demo@plant.app', name: 'Ece'),
    );
  }

  void updateName(String name) {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(AuthUser(id: current.user.id, email: current.user.email, name: name));
    }
  }

  Future<void> logout() async {
    await AppStorage.instance.delete(key: 'auth_token');
    state = const AuthUnauthenticated();
  }
}
