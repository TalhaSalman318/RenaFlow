import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/live_session_model.dart';

class DashboardController extends StateNotifier<LiveSessionModel> {
  DashboardController() : super(_initialSession) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const _sessionDuration = Duration(hours: 4);
  static final _initialSession = LiveSessionModel(
    elapsedTime: const Duration(hours: 2, minutes: 18),
    totalDuration: _sessionDuration,
    ufRate: 0.82,
    bloodFlowRate: 280,
    heartRate: 72,
    bloodPressure: '128/78',
    completionPercentage: 0.575,
  );

  late final Timer _timer;
  int _tickCount = 0;

  void _tick() {
    if (!mounted) return;
    _tickCount++;
    final nextElapsed = state.elapsedTime + const Duration(minutes: 1);
    final elapsed = nextElapsed > state.totalDuration
        ? state.totalDuration
        : nextElapsed;
    final progress = elapsed.inSeconds / state.totalDuration.inSeconds;
    final heartRate = 72 + ((_tickCount % 7) - 3);
    final systolic = 128 + ((_tickCount % 5) - 2);
    final diastolic = 78 + ((_tickCount % 3) - 1);

    state = state.copyWith(
      elapsedTime: elapsed,
      heartRate: heartRate,
      bloodPressure: '$systolic/$diastolic',
      completionPercentage: progress.clamp(0, 1),
      ufRate: 0.82 + ((_tickCount % 4) * 0.01),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, LiveSessionModel>(
      (ref) => DashboardController(),
    );
