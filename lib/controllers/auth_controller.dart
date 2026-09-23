import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final String identifier;
  final String password;
  final String? identifierError;
  final String? passwordError;
  final bool isLoading;
  final bool isPasswordVisible;
  final UserRole selectedRole;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  void selectRole(UserRole role) {
    state = AuthState(
      identifier: state.identifier,
      password: state.password,
      identifierError: state.identifierError,
      passwordError: state.passwordError,
      isLoading: state.isLoading,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: role,
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
    );
  }

  bool validate() {
    final identifierError = state.identifier.trim().isEmpty
        ? 'Email or Medical ID is required'
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
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = AuthState(
      identifier: state.identifier,
      password: state.password,
      isPasswordVisible: state.isPasswordVisible,
      selectedRole: state.selectedRole,
    );
    return true;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
