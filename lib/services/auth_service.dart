import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'network_error.dart';

class AuthSession {
  const AuthSession({required this.user, required this.accessToken});

  final Map<String, dynamic> user;
  final String accessToken;

  String get role => user['role'] as String? ?? 'patient';
  String get userId => (user['id'] ?? user['_id'] ?? '').toString();
}

class AuthService {
  AuthService(this._api, this._preferences);

  final ApiService _api;
  final SharedPreferences _preferences;

  Future<AuthSession> login(String identifier, String password) async {
    final normalizedIdentifier = identifier.trim().toLowerCase() == 'admin'
        ? 'admin@renalflow.com'
        : identifier.trim();
    debugApiLog('Login request identifier: $normalizedIdentifier');
    final data = await _api.post('/auth/login', {
      'identifier': normalizedIdentifier,
      'password': password,
    });
    final token = data['accessToken'] as String?;
    final user = (data['user'] as Map<dynamic, dynamic>?)
        ?.cast<String, dynamic>();
    if (token == null || user == null) {
      throw const ApiException('The login response was incomplete.');
    }
    final accessToken = token.trim();
    if (accessToken.isEmpty) {
      throw const ApiException(
        'The login response contained an invalid token.',
      );
    }
    await _preferences.setString(ApiService.tokenKey, accessToken);
    _api.resetAuthExpirySignal();
    return AuthSession(user: user, accessToken: accessToken);
  }

  Future<AuthSession> register(Map<String, dynamic> body) async {
    final data = await _api.post('/auth/register', body);
    final user = (data['user'] as Map<dynamic, dynamic>?)
        ?.cast<String, dynamic>();
    if (user == null) {
      throw const ApiException('The registration response was incomplete.');
    }
    return AuthSession(user: user, accessToken: '');
  }

  Future<Map<String, dynamic>> currentUser() async {
    final data = await _api.get('/auth/me');
    return (data['user'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
        data;
  }

  Future<void> logout() => _preferences.remove(ApiService.tokenKey);
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(apiServiceProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);
