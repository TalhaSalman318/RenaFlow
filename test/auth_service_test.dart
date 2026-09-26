import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rena_flow/main.dart';
import 'package:rena_flow/services/api_service.dart';
import 'package:rena_flow/services/auth_service.dart';
import 'package:rena_flow/services/socket_service.dart';

void main() {
  test(
    'login persists its access token and API requests send Bearer auth',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      var loginIdentifier = '';
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          loginIdentifier = body['identifier'] as String;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'patient-access-token',
                'user': {
                  'id': 'patient-user-1',
                  'role': 'patient',
                  'medicalId': 'PT-2026-0001',
                },
              },
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer patient-access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'patient': {}},
          }),
          200,
        );
      });
      addTearDown(client.close);

      final api = ApiService(preferences, client: client);
      final auth = AuthService(api, preferences);
      final session = await auth.login('PT-2026-0001', 'patient-password');
      await api.get('/patients/me');

      expect(loginIdentifier, 'PT-2026-0001');
      expect(session.accessToken, 'patient-access-token');
      expect(
        preferences.getString(ApiService.tokenKey),
        'patient-access-token',
      );
    },
  );

  test(
    '401 clears the stored token and signals the app to return to login',
    () async {
      SharedPreferences.setMockInitialValues({
        ApiService.tokenKey: 'expired-access-token',
      });
      final preferences = await SharedPreferences.getInstance();
      var expirySignaled = false;
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer expired-access-token');
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'INVALID_AUTHENTICATION',
              'message': 'The access token is invalid or expired.',
            },
          }),
          401,
        );
      });
      addTearDown(client.close);

      final api = ApiService(
        preferences,
        client: client,
        onUnauthorized: () => expirySignaled = true,
      );

      await expectLater(api.get('/patients/me'), throwsA(isA<ApiException>()));

      expect(preferences.getString(ApiService.tokenKey), isNull);
      expect(expirySignaled, isTrue);
    },
  );

  testWidgets('auth expiry clears session and returns to sign in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ApiService.tokenKey: 'expired-access-token',
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          socketServiceProvider.overrideWithValue(null),
        ],
        child: const RenalFlowApp(),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(RenalFlowApp)),
    );
    container.read(authSessionExpiredProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(preferences.getString(ApiService.tokenKey), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
