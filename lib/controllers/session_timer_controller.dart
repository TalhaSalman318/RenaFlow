import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/bed_matrix_controller.dart';

enum SessionTimerStatus { idle, running, paused, delayed, completed }

class BedSessionTimer {
  const BedSessionTimer({
    required this.bedId,
    required this.remainingSeconds,
    required this.elapsedSeconds,
    required this.delayMinutes,
    required this.status,
    this.delayReason,
  });

  final String bedId;
  final int remainingSeconds;
  final int elapsedSeconds;
  final int delayMinutes;
  final SessionTimerStatus status;
  final String? delayReason;

  BedSessionTimer copyWith({
    int? remainingSeconds,
    int? elapsedSeconds,
    int? delayMinutes,
    SessionTimerStatus? status,
    String? delayReason,
  }) {
    return BedSessionTimer(
      bedId: bedId,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      status: status ?? this.status,
      delayReason: delayReason ?? this.delayReason,
    );
  }
}

class SessionTimerController
    extends StateNotifier<Map<String, BedSessionTimer>> {
  SessionTimerController(this._ref) : super(const {}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final Ref _ref;
  late final Timer _timer;

  void startSession(String bedId, {int durationMinutes = 240}) {
    state = {
      ...state,
      bedId: BedSessionTimer(
        bedId: bedId,
        remainingSeconds: durationMinutes * 60,
        elapsedSeconds: 0,
        delayMinutes: 0,
        status: SessionTimerStatus.running,
      ),
    };
    _ref.read(bedMatrixControllerProvider.notifier).setActive(bedId);
  }

  void pauseSession(String bedId) =>
      _setStatus(bedId, SessionTimerStatus.paused);

  void resumeSession(String bedId) =>
      _setStatus(bedId, SessionTimerStatus.running);

  void stopSession(String bedId) {
    final current = state[bedId];
    if (current == null) return;
    state = {
      ...state,
      bedId: current.copyWith(status: SessionTimerStatus.completed),
    };
    _ref.read(bedMatrixControllerProvider.notifier).setVacant(bedId);
  }

  void addDelay(String bedId, int minutes, String reason) {
    final current = state[bedId];
    if (current == null) return;
    state = {
      ...state,
      bedId: current.copyWith(
        remainingSeconds: current.remainingSeconds + minutes * 60,
        delayMinutes: current.delayMinutes + minutes,
        delayReason: reason,
      ),
    };
  }

  void applyRemoteTick(Map<String, dynamic> json) {
    final bedId = json['bedId']?.toString();
    if (bedId == null || bedId.isEmpty) return;
    final current = state[bedId];
    final status = switch (json['status']?.toString()) {
      'running' => SessionTimerStatus.running,
      'paused' => SessionTimerStatus.paused,
      'delayed' => SessionTimerStatus.delayed,
      'completed' => SessionTimerStatus.completed,
      _ => SessionTimerStatus.idle,
    };
    state = {
      ...state,
      bedId: BedSessionTimer(
        bedId: bedId,
        remainingSeconds:
            (json['remainingSeconds'] as num?)?.toInt() ??
            current?.remainingSeconds ??
            0,
        elapsedSeconds:
            (json['elapsedSeconds'] as num?)?.toInt() ??
            current?.elapsedSeconds ??
            0,
        delayMinutes:
            (json['delayMinutes'] as num?)?.toInt() ??
            current?.delayMinutes ??
            0,
        delayReason: json['delayReason'] as String? ?? current?.delayReason,
        status: status,
      ),
    };
    if (status == SessionTimerStatus.running) {
      _ref.read(bedMatrixControllerProvider.notifier).setActive(bedId);
    }
  }

  void _setStatus(String bedId, SessionTimerStatus status) {
    final current = state[bedId];
    if (current != null) {
      state = {...state, bedId: current.copyWith(status: status)};
    }
  }

  void _tick() {
    if (!mounted) return;
    final next = <String, BedSessionTimer>{...state};
    for (final entry in state.entries) {
      final session = entry.value;
      if (session.status != SessionTimerStatus.running) {
        continue;
      }
      if (session.remainingSeconds <= 1) {
        next[entry.key] = session.copyWith(
          remainingSeconds: 0,
          status: SessionTimerStatus.completed,
        );
        _ref.read(bedMatrixControllerProvider.notifier).setVacant(entry.key);
      } else {
        next[entry.key] = session.copyWith(
          remainingSeconds: session.remainingSeconds - 1,
          elapsedSeconds: session.elapsedSeconds + 1,
        );
      }
    }
    state = next;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final sessionTimerControllerProvider =
    StateNotifierProvider<SessionTimerController, Map<String, BedSessionTimer>>(
      (ref) => SessionTimerController(ref),
    );
