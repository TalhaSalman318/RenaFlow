import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/bed_matrix_controller.dart';
import '../services/session_service.dart';

enum SessionTimerStatus { idle, running, paused, delayed, completed }

class BedSessionTimer {
  const BedSessionTimer({
    required this.bedId,
    required this.remainingSeconds,
    required this.elapsedSeconds,
    required this.delayMinutes,
    required this.status,
    this.patientId,
    this.sessionId,
    this.patientMedicalId,
    this.totalDurationMinutes = 240,
    this.delayReason,
  });

  final String bedId;
  final int remainingSeconds;
  final int elapsedSeconds;
  final int delayMinutes;
  final SessionTimerStatus status;
  final String? patientId;
  final String? sessionId;
  final String? patientMedicalId;
  final int totalDurationMinutes;
  final String? delayReason;

  double get completionPercentage => totalDurationMinutes <= 0
      ? 0
      : (elapsedSeconds / (totalDurationMinutes * 60)).clamp(0.0, 1.0);

  BedSessionTimer copyWith({
    int? remainingSeconds,
    int? elapsedSeconds,
    int? delayMinutes,
    SessionTimerStatus? status,
    String? patientId,
    String? sessionId,
    String? patientMedicalId,
    int? totalDurationMinutes,
    String? delayReason,
  }) {
    return BedSessionTimer(
      bedId: bedId,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      status: status ?? this.status,
      patientId: patientId ?? this.patientId,
      sessionId: sessionId ?? this.sessionId,
      patientMedicalId: patientMedicalId ?? this.patientMedicalId,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
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

  Future<void> hydratePatientSession({
    required String patientId,
    required String patientMedicalId,
    String? assignedBedId,
  }) async {
    final timer = await _ref
        .read(sessionServiceProvider)
        .activeForPatient(patientId);
    if (timer == null) {
      final bedId = assignedBedId;
      final current = bedId == null ? null : state[bedId];
      if (bedId != null &&
          current != null &&
          (current.patientMedicalId == null ||
              current.patientMedicalId == patientMedicalId)) {
        final next = {...state}..remove(bedId);
        state = next;
      }
      return;
    }
    applyRemoteTick({
      ...timer,
      if (timer['patientMedicalId'] == null)
        'patientMedicalId': patientMedicalId,
    });
  }

  Future<void> startSession(
    String bedId, {
    String? patientId,
    String? patientMedicalId,
    int durationMinutes = 240,
  }) async {
    final timer = await _ref
        .read(sessionServiceProvider)
        .start(
          bedId: bedId,
          patientId: patientId,
          totalDurationMinutes: durationMinutes,
        );
    applyRemoteTick({
      ...timer,
      'bedId': bedId,
      'patientMedicalId': patientMedicalId,
    });
  }

  Future<void> pauseSession(String bedId) async {
    final timer = await _ref
        .read(sessionServiceProvider)
        .pause(bedId: bedId, sessionId: state[bedId]?.sessionId);
    applyRemoteTick({...timer, 'bedId': bedId});
  }

  Future<void> resumeSession(String bedId) async {
    final timer = await _ref
        .read(sessionServiceProvider)
        .resume(bedId: bedId, sessionId: state[bedId]?.sessionId);
    applyRemoteTick({...timer, 'bedId': bedId});
  }

  Future<void> stopSession(String bedId) async {
    final timer = await _ref
        .read(sessionServiceProvider)
        .stop(bedId: bedId, sessionId: state[bedId]?.sessionId);
    applyRemoteTick({...timer, 'bedId': bedId});
  }

  Future<void> addDelay(String bedId, int minutes, String reason) async {
    final timer = await _ref
        .read(sessionServiceProvider)
        .delay(
          bedId: bedId,
          sessionId: state[bedId]?.sessionId,
          minutes: minutes,
          reason: reason,
        );
    applyRemoteTick({...timer, 'bedId': bedId});
  }

  void applyRemoteTick(Map<String, dynamic> json) {
    final bedId = json['bedId']?.toString();
    if (bedId == null || bedId.isEmpty) return;
    final current = state[bedId];
    final incomingSessionId = json['sessionId']?.toString();
    final status = switch (json['status']?.toString()) {
      'active' || 'running' => SessionTimerStatus.running,
      'paused' => SessionTimerStatus.paused,
      'delayed' => SessionTimerStatus.delayed,
      'completed' => SessionTimerStatus.completed,
      _ => SessionTimerStatus.idle,
    };
    final incomingElapsed = (json['elapsedSeconds'] as num?)?.toInt() ?? 0;
    final isSameSession =
        current != null &&
        current.sessionId != null &&
        incomingSessionId != null &&
        current.sessionId == incomingSessionId;
    if (current != null &&
        isSameSession &&
        incomingElapsed < current.elapsedSeconds &&
        current.status == SessionTimerStatus.paused &&
        (status == SessionTimerStatus.running ||
            status == SessionTimerStatus.delayed)) {
      return;
    }
    if (current != null &&
        isSameSession &&
        current.status == SessionTimerStatus.completed &&
        status != SessionTimerStatus.completed) {
      return;
    }
    final isStaleTick =
        current != null &&
        isSameSession &&
        incomingElapsed < current.elapsedSeconds;
    final rawPatientId = json['patientId'];
    final patientId = rawPatientId is Map
        ? (rawPatientId['_id'] ?? rawPatientId['id'])?.toString()
        : rawPatientId?.toString();
    state = {
      ...state,
      bedId: BedSessionTimer(
        bedId: bedId,
        remainingSeconds:
            (isStaleTick ? null : json['remainingSeconds'] as num?)?.toInt() ??
            current?.remainingSeconds ??
            0,
        elapsedSeconds:
            (isStaleTick ? null : json['elapsedSeconds'] as num?)?.toInt() ??
            current?.elapsedSeconds ??
            0,
        delayMinutes:
            (json['delayMinutes'] as num?)?.toInt() ??
            current?.delayMinutes ??
            0,
        sessionId: json['sessionId']?.toString() ?? current?.sessionId,
        patientId: patientId ?? current?.patientId,
        patientMedicalId:
            json['patientMedicalId']?.toString() ?? current?.patientMedicalId,
        totalDurationMinutes:
            (json['totalDurationMinutes'] as num?)?.toInt() ??
            (json['durationMinutes'] as num?)?.toInt() ??
            current?.totalDurationMinutes ??
            240,
        delayReason: json['delayReason'] as String? ?? current?.delayReason,
        status: status,
      ),
    };
    if (status == SessionTimerStatus.completed) {
      unawaited(_ref.read(bedMatrixControllerProvider.notifier).load());
    }
  }

  void _tick() {
    if (!mounted) return;
    final next = <String, BedSessionTimer>{...state};
    for (final entry in state.entries) {
      final session = entry.value;
      if (session.status != SessionTimerStatus.running &&
          session.status != SessionTimerStatus.delayed) {
        continue;
      }
      if (session.remainingSeconds <= 1) {
        next[entry.key] = session.copyWith(
          remainingSeconds: 0,
          status: SessionTimerStatus.completed,
        );
        unawaited(_ref.read(bedMatrixControllerProvider.notifier).load());
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
