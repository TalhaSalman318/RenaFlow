import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../controllers/bed_matrix_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/session_timer_controller.dart';
import 'api_service.dart';
import 'notification_service.dart';

const socketBaseUrl = String.fromEnvironment(
  'SOCKET_URL',
  defaultValue: 'http://localhost:4000',
);

class SocketService {
  SocketService(this._ref, this._token) {
    _socket = io.io(
      socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket.on('bed:status-changed', _onBedChanged);
    _socket.on('session:tick', _onSessionTick);
    _socket.on('timer_tick', _onSessionTick);
    _socket.on('session_started', _onSessionTick);
    _socket.on('session_paused', _onSessionTick);
    _socket.on('session_resumed', _onSessionTick);
    _socket.on('session_stopped', _onSessionTick);
    _socket.on('appointment:pre-session-alert', _onPreSessionAlert);
    _socket.connect();
  }

  final Ref _ref;
  final String? _token;
  late final io.Socket _socket;

  void _onBedChanged(dynamic payload) {
    final root = _map(payload) ?? <String, dynamic>{};
    final bed = _map(root['bed']) ?? root;
    if (bed.isNotEmpty) {
      _ref.read(bedMatrixControllerProvider.notifier).applyRemoteBed(bed);
    }
  }

  void _onSessionTick(dynamic payload) {
    final tick = _map(payload) ?? <String, dynamic>{};
    if (tick.isNotEmpty) {
      _ref.read(sessionTimerControllerProvider.notifier).applyRemoteTick(tick);
    }
  }

  void _onPreSessionAlert(dynamic payload) {
    final root = _map(payload) ?? <String, dynamic>{};
    final appointment = _map(root['appointment']) ?? root;
    _ref
        .read(notificationServiceProvider.notifier)
        .showAlert(
          (appointment['patientName'] ?? appointment['patientId'] ?? 'Patient')
              .toString(),
          'Bed ${appointment['bedNumber'] ?? appointment['bedId'] ?? 'pending'}',
        );
  }

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  void dispose() => _socket.dispose();
}

final socketServiceProvider = Provider<SocketService?>((ref) {
  ref.watch(authControllerProvider);
  String? token;
  try {
    token = ref.watch(sharedPreferencesProvider).getString(ApiService.tokenKey);
  } on StateError {
    return null;
  }
  if (token == null || token.isEmpty) return null;
  final service = SocketService(ref, token);
  ref.onDispose(service.dispose);
  return service;
});
