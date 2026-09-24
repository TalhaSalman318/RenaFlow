import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'network_error.dart';

const defaultApiBaseUrl = 'http://localhost:4000/api/v1';
const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
final apiBaseUrl = configuredApiBaseUrl.isEmpty
    ? defaultApiBaseUrl
    : configuredApiBaseUrl;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this._preferences, {http.Client? client})
    : _client = client ?? http.Client();

  static const tokenKey = 'renalflow_access_token';
  final SharedPreferences _preferences;
  final http.Client _client;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) => _request('GET', path, queryParameters: queryParameters);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) => _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '$apiBaseUrl$path',
    ).replace(queryParameters: queryParameters);
    final token = _preferences.getString(tokenKey);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    // Keep credentials out of logs while making connection and auth failures distinguishable.
    debugApiLog('$method $uri');

    late final http.Response response;
    try {
      response = method == 'GET'
          ? await _client.get(uri, headers: headers)
          : await _client.post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? <String, dynamic>{}),
            );
    } on SocketException catch (error) {
      debugApiLog('$method $uri -> connection refused/unavailable: $error');
      throw ApiException(
        'Unable to connect to RenalFlow at $apiBaseUrl. Ensure the backend is running on port 4000.',
      );
    } on http.ClientException catch (error) {
      debugApiLog('$method $uri -> HTTP client connection error: $error');
      throw ApiException(
        'Unable to connect to RenalFlow at $apiBaseUrl. Ensure the backend is running on port 4000.',
      );
    } catch (error) {
      debugApiLog('$method $uri -> transport error: $error');
      throw ApiException('Unable to reach RenalFlow services: $error');
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload['success'] != true) {
      final error = payload['error'];
      debugApiLog(
        '$method $uri -> HTTP ${response.statusCode} ${payload['error']}',
      );
      throw ApiException(
        error is Map<String, dynamic>
            ? (error['message'] as String? ?? 'Request failed.')
            : 'Request failed.',
        statusCode: response.statusCode,
        code: error is Map<String, dynamic> ? error['code'] as String? : null,
      );
    }
    return (payload['data'] as Map<dynamic, dynamic>?)
            ?.cast<String, dynamic>() ??
        <String, dynamic>{};
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden in main().');
});

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(sharedPreferencesProvider)),
);
