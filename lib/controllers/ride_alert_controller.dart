import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ride_alert_model.dart';

class RideAlertState {
  const RideAlertState({required this.ride, required this.remainingSeconds});

  final RideAlertModel ride;
  final int remainingSeconds;

  RideAlertState copyWith({RideAlertModel? ride, int? remainingSeconds}) {
    return RideAlertState(
      ride: ride ?? this.ride,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class RideAlertController extends StateNotifier<RideAlertState> {
  RideAlertController()
    : super(
        RideAlertState(
          ride: RideAlertModel(
            driverName: 'Amina Khan',
            vehicleNumber: 'RF-2048',
            etaMinutes: 8,
            pickupTime: DateTime.now().add(const Duration(minutes: 8)),
            isConfirmed: false,
          ),
          remainingSeconds: 8 * 60,
        ),
      ) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  late final Timer _timer;

  void _tick() {
    if (!mounted || state.ride.isConfirmed || state.remainingSeconds <= 0) {
      return;
    }
    final remaining = state.remainingSeconds - 1;
    state = state.copyWith(
      remainingSeconds: remaining,
      ride: state.ride.copyWith(etaMinutes: (remaining / 60).ceil()),
    );
  }

  void confirmPickup() {
    if (state.ride.isConfirmed) return;
    state = state.copyWith(ride: state.ride.copyWith(isConfirmed: true));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final rideAlertControllerProvider =
    StateNotifierProvider.autoDispose<RideAlertController, RideAlertState>(
      (ref) => RideAlertController(),
    );
