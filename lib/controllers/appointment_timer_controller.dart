import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../models/bed_model.dart';
import 'appointment_controller.dart';
import 'bed_matrix_controller.dart';

enum AppointmentOperationalStatus {
  scheduled,
  preparingForPickup,
  patientNotified,
  active,
  completed,
}

class AppointmentTimerSnapshot {
  const AppointmentTimerSnapshot({
    required this.appointment,
    required this.remaining,
    required this.status,
    this.currentBed,
  });

  final AppointmentModel appointment;
  final Duration remaining;
  final AppointmentOperationalStatus status;
  final BedModel? currentBed;

  bool get isWithin24Hours => remaining > Duration.zero && remaining <= _day;
  bool get isWithin30Minutes =>
      remaining > Duration.zero && remaining <= _thirtyMinutes;
  bool get hasStarted => remaining <= Duration.zero;
  bool get hasOverlap =>
      isWithin30Minutes &&
      currentBed != null &&
      currentBed!.status == BedStatus.occupied &&
      currentBed!.patientName != null &&
      currentBed!.patientName != appointment.patientName;

  String get countdown {
    final totalSeconds = remaining.inSeconds.clamp(0, 24 * 60 * 60);
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get statusLabel {
    return switch (status) {
      AppointmentOperationalStatus.scheduled => 'Scheduled',
      AppointmentOperationalStatus.preparingForPickup => 'Preparing for pickup',
      AppointmentOperationalStatus.patientNotified => 'Patient notified',
      AppointmentOperationalStatus.active => 'Session active',
      AppointmentOperationalStatus.completed => 'Completed',
    };
  }

  static const _day = Duration(days: 1);
  static const _thirtyMinutes = Duration(minutes: 30);
}

class AppointmentTimerState {
  const AppointmentTimerState({required this.now, required this.sessions});

  final DateTime now;
  final Map<String, AppointmentTimerSnapshot> sessions;

  AppointmentTimerSnapshot? forAppointment(String appointmentId) =>
      sessions[appointmentId];

  AppointmentTimerSnapshot? forPatient(String patientName) {
    for (final snapshot in sessions.values) {
      if (snapshot.appointment.patientName == patientName) return snapshot;
    }
    return null;
  }

  AppointmentTimerSnapshot? forBed(String bedId) {
    for (final snapshot in sessions.values) {
      if (snapshot.appointment.bedId == bedId) return snapshot;
    }
    return null;
  }

  List<AppointmentTimerSnapshot> get preparingSessions => sessions.values
      .where((snapshot) => snapshot.isWithin30Minutes)
      .toList(growable: false);
}

class AppointmentTimerController extends StateNotifier<AppointmentTimerState> {
  AppointmentTimerController(this._ref)
    : super(_buildState(DateTime.now(), _ref)) {
    _ref.listen<AppointmentState>(appointmentControllerProvider, (_, _) {
      _refresh();
    });
    _ref.listen<BedMatrixState>(bedMatrixControllerProvider, (_, _) {
      _refresh();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  final Ref _ref;
  late final Timer _ticker;
  final List<void Function(AppointmentTimerSnapshot)> _statusHooks = [];
  final Map<String, AppointmentOperationalStatus> _lastStatuses = {};

  void addStatusHook(void Function(AppointmentTimerSnapshot) hook) {
    _statusHooks.add(hook);
  }

  void removeStatusHook(void Function(AppointmentTimerSnapshot) hook) {
    _statusHooks.remove(hook);
  }

  void _refresh() {
    final next = _buildState(DateTime.now(), _ref);
    for (final snapshot in next.sessions.values) {
      final previous = _lastStatuses[snapshot.appointment.id];
      if (previous != snapshot.status) {
        _lastStatuses[snapshot.appointment.id] = snapshot.status;
        for (final hook in List.of(_statusHooks)) {
          hook(snapshot);
        }
      }
    }
    state = next;
  }

  static AppointmentTimerState _buildState(DateTime now, Ref ref) {
    final appointments = ref.read(appointmentControllerProvider).appointments;
    final beds = ref.read(bedMatrixControllerProvider).beds;
    final bedById = {for (final bed in beds) bed.bedId: bed};
    return AppointmentTimerState(
      now: now,
      sessions: {
        for (final appointment in appointments)
          appointment.id: _snapshotFor(
            appointment,
            now,
            bedById[appointment.bedId],
          ),
      },
    );
  }

  static AppointmentTimerSnapshot _snapshotFor(
    AppointmentModel appointment,
    DateTime now,
    BedModel? currentBed,
  ) {
    final remaining = appointment.startTime.difference(now);
    final status = remaining <= Duration.zero
        ? AppointmentOperationalStatus.active
        : remaining <= const Duration(minutes: 30)
        ? AppointmentOperationalStatus.patientNotified
        : remaining <= const Duration(hours: 24)
        ? AppointmentOperationalStatus.preparingForPickup
        : AppointmentOperationalStatus.scheduled;
    return AppointmentTimerSnapshot(
      appointment: appointment,
      remaining: remaining,
      status: status,
      currentBed: currentBed,
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }
}

final appointmentTimerControllerProvider =
    StateNotifierProvider<AppointmentTimerController, AppointmentTimerState>(
      (ref) => AppointmentTimerController(ref),
    );
