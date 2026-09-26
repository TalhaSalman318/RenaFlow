import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

enum UserRole { patient, admin }

class AuthState {
  const AuthState({
    this.identifier = '',
    this.password = '',
    this.identifierError,
    this.passwordError,
    this.isLoading = false,
    this.isPasswordVisible = false,
    this.selectedRole = UserRole.patient,
    this.errorMessage,
    this.user,
  });

  final String identifier;
  final String password;
  final String? identifierError;
  final String? passwordError;
  final bool isLoading;
  final bool isPasswordVisible;
  final UserRole selectedRole;
  final String? errorMessage;
  final Map<String, dynamic>? user;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController([this._authService]) : super(const AuthState());

  final AuthService? _authService;

  void selectRole(UserRole role) {
    state = AuthState(
      identifier: state.identifier,
      password: state.password,
      identifierError: state.identifierError,
      passwordError: state.passwordError,
      isLoading: state.isLoading,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: role,
      errorMessage: state.errorMessage,
      user: state.user,
    );
  }

  void setIdentifier(String value) {
    state = AuthState(
      identifier: value,
      password: state.password,
      passwordError: state.passwordError,
      isLoading: state.isLoading,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: state.selectedRole,
      errorMessage: null,
      user: state.user,
    );
  }

  void setPassword(String value) {
    state = AuthState(
      identifier: state.identifier,
      password: value,
      identifierError: state.identifierError,
      isLoading: state.isLoading,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: state.selectedRole,
      errorMessage: state.errorMessage,
      user: state.user,
    );
  }

  void togglePasswordVisibility() {
    state = AuthState(
      identifier: state.identifier,
      password: state.password,
      identifierError: state.identifierError,
      passwordError: state.passwordError,
      isLoading: state.isLoading,
      isPasswordVisible: !state.isPasswordVisible,
      selectedRole: state.selectedRole,
      errorMessage: state.errorMessage,
      user: state.user,
    );
  }

  bool validate() {
    final identifierError = state.identifier.trim().isEmpty
        ? 'Medical ID or Email is required'
        : null;
    final passwordError = state.password.isEmpty
        ? 'Password is required'
        : state.password.length < 6
        ? 'Password must be at least 6 characters'
        : null;
    state = AuthState(
      identifier: state.identifier,
      password: state.password,
      identifierError: identifierError,
      passwordError: passwordError,
      isLoading: state.isLoading,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: state.selectedRole,
      errorMessage: state.errorMessage,
      user: state.user,
    );
    return identifierError == null && passwordError == null;
  }

  Future<bool> signIn() async {
    if (!validate()) return false;
    state = AuthState(
      identifier: state.identifier,
      password: state.password,
      isLoading: true,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: state.selectedRole,
      errorMessage: null,
      user: state.user,
    );
    if (_authService == null) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      state = AuthState(
        identifier: state.identifier,
        password: state.password,
        isPasswordVisible: state.isPasswordVisible,
        selectedRole: state.selectedRole,
      );
      return true;
    }
    try {
      final session = await _authService.login(
        state.identifier,
        state.password,
      );
      state = AuthState(
        identifier: state.identifier,
        password: state.password,
        isPasswordVisible: state.isPasswordVisible,
        selectedRole: session.role == 'admin' || session.role == 'nurse'
            ? UserRole.admin
            : UserRole.patient,
        user: session.user,
      );
      return true;
    } on ApiException catch (error) {
      state = AuthState(
        identifier: state.identifier,
        password: state.password,
        isPasswordVisible: state.isPasswordVisible,
        selectedRole: state.selectedRole,
        errorMessage: error.message,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService?.logout();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authServiceProvider)),
);
