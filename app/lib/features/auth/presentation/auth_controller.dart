import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../models/user_model.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.checkedSession = false,
  });

  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool checkedSession;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? clearUser,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? checkedSession,
  }) {
    return AuthState(
      user: clearUser == true ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      checkedSession: checkedSession ?? this.checkedSession,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(isLoading: true)) {
    checkSession();
  }

  final Ref _ref;

  Future<void> checkSession() async {
    try {
      final user = await _ref.read(authRepositoryProvider).loadCurrentUser();
      state = AuthState(user: user, checkedSession: true);
    } catch (_) {
      state = const AuthState(checkedSession: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .login(email, password);
      state = AuthState(user: user, checkedSession: true);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(authRepositoryProvider).register(name, email, password);

      state = const AuthState(checkedSession: true);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = const AuthState(checkedSession: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);
