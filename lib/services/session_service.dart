import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';

class SessionService {
  SessionService(this._api);

  final ApiService _api;

  Future<Map<String, dynamic>?> activeForPatient(String patientId) async {
    final data = await _api.get(
      '/sessions/active/${Uri.encodeComponent(patientId)}',
    );
    final timer = data['timer'];
    return timer is Map ? timer.cast<String, dynamic>() : null;
  }

  Future<Map<String, dynamic>> start({
    required String bedId,
    String? patientId,
    int totalDurationMinutes = 240,
  }) => _timerAction('/sessions/start', {
    'bedId': bedId.replaceFirst('Bed ', ''),
    'patientId': ?patientId,
    'totalDurationMinutes': totalDurationMinutes,
  });

  Future<Map<String, dynamic>> pause({
    required String bedId,
    String? sessionId,
  }) => _timerAction('/sessions/pause', {
    'bedId': bedId.replaceFirst('Bed ', ''),
    'sessionId': ?sessionId,
  });

  Future<Map<String, dynamic>> resume({
    required String bedId,
    String? sessionId,
  }) => _timerAction('/sessions/resume', {
    'bedId': bedId.replaceFirst('Bed ', ''),
    'sessionId': ?sessionId,
  });

  Future<Map<String, dynamic>> stop({
    required String bedId,
    String? sessionId,
  }) => _timerAction('/sessions/stop', {
    'bedId': bedId.replaceFirst('Bed ', ''),
    'sessionId': ?sessionId,
  });

  Future<Map<String, dynamic>> delay({
    required String bedId,
    required int minutes,
    required String reason,
    String? sessionId,
  }) => _timerAction('/sessions/delay', {
    'bedId': bedId.replaceFirst('Bed ', ''),
    'delayMinutes': minutes,
    'reason': reason,
  });

  Future<Map<String, dynamic>> _timerAction(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.post(path, body);
    final timer = data['timer'];
    if (timer is Map) return timer.cast<String, dynamic>();
    final session = data['session'];
    if (session is Map) return session.cast<String, dynamic>();
    throw const ApiException('The session timer was not returned.');
  }
}

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(ref.watch(apiServiceProvider)),
);
