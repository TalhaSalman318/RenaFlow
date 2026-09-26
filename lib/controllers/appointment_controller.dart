import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/appointment_model.dart';
import '../models/bed_model.dart';
import 'admin_patient_controller.dart';
import 'bed_matrix_controller.dart';
import '../services/appointment_service.dart';

class ShiftAvailability {
  const ShiftAvailability({required this.shift, required this.availableBeds});

  final String shift;
  final int availableBeds;

  bool get isFull => availableBeds == 0;
}

class AppointmentState {
  const AppointmentState({
    required this.appointments,
    this.selectedDays = const [],
    this.selectedShift,
    this.availableBeds = const {},
  });

  final List<AppointmentModel> appointments;
  final List<int> selectedDays;
  final String? selectedShift;
  final Map<String, List<BedModel>> availableBeds;

  AppointmentState copyWith({
    List<AppointmentModel>? appointments,
    List<int>? selectedDays,
    String? selectedShift,
    bool clearShift = false,
    Map<String, List<BedModel>>? availableBeds,
  }) => AppointmentState(
    appointments: appointments ?? this.appointments,
    selectedDays: selectedDays ?? this.selectedDays,
    selectedShift: clearShift ? null : selectedShift ?? this.selectedShift,
    availableBeds: availableBeds ?? this.availableBeds,
  );
}

class AppointmentController extends StateNotifier<AppointmentState> {
  AppointmentController(this._ref) : super(_seedState);

  final Ref _ref;

  Future<List<BedModel>> fetchAvailableBeds() async {
    final selectedShift = state.selectedShift;
    if (selectedShift == null || state.selectedDays.isEmpty) return const [];
    final availability = await _ref
        .read(appointmentServiceProvider)
        .availability(
          selectedDays: state.selectedDays,
          shift: _backendShift(selectedShift),
        );
    return availability.beds;
  }

  Future<void> schedule({
    required String patientId,
    required String bedId,
    required String startTimeLocal,
    required String endTimeLocal,
  }) async {
    final appointments = await _ref
        .read(appointmentServiceProvider)
        .schedule(
          patientId: patientId,
          bedId: bedId,
          selectedDays: state.selectedDays,
          shift: _backendShift(state.selectedShift ?? shifts.first),
          startTimeLocal: startTimeLocal,
          endTimeLocal: endTimeLocal,
        );
    if (appointments.isNotEmpty) {
      state = state.copyWith(
        appointments: [...state.appointments, ...appointments],
      );
    }
    await _ref.read(bedMatrixControllerProvider.notifier).load();
    await _ref.read(adminPatientControllerProvider.notifier).refresh();
  }

  String _backendShift(String shift) => shift.split(' · ').first;

  static const shifts = [
    'Morning · 08:00 AM - 12:00 PM',
    'Afternoon · 01:00 PM - 05:00 PM',
    'Evening · 06:00 PM - 10:00 PM',
  ];

  static final _seedState = AppointmentState(appointments: []);

  void addAppointment(AppointmentModel appointment) {
    state = state.copyWith(appointments: [...state.appointments, appointment]);
  }

  void setSelectedDays(List<int> days) {
    state = state.copyWith(selectedDays: [...days]..sort(), clearShift: true);
    unawaited(loadAvailability());
  }

  void setSelectedShift(String shift) {
    state = state.copyWith(selectedShift: shift);
    unawaited(loadAvailability());
  }

  Future<void> loadAvailability() async {
    if (state.selectedDays.isEmpty) return;
    final next = <String, List<BedModel>>{...state.availableBeds};
    for (final shift in shifts) {
      try {
        final result = await _ref
            .read(appointmentServiceProvider)
            .availability(
              selectedDays: state.selectedDays,
              shift: _backendShift(shift),
            );
        next[shift] = result.beds;
        if (mounted) state = state.copyWith(availableBeds: next);
      } catch (_) {}
    }
  }

  List<ShiftAvailability> getAvailableShiftsForDays(List<String> selectedDays) {
    final weekdays = selectedDays.map(_weekdayNumber).toSet();
    final beds = _ref.read(bedMatrixControllerProvider).beds;
    final vacantCount = beds
        .where((bed) => bed.status == BedStatus.vacant)
        .length;
    return shifts.map((shift) {
      final remoteBeds = state.availableBeds[shift];
      final booked = state.appointments.where((appointment) {
        return appointment.shift == shift &&
            appointment.weekdays.any(weekdays.contains);
      }).length;
      return ShiftAvailability(
        shift: shift,
        availableBeds:
            remoteBeds?.length ?? (vacantCount - booked).clamp(0, vacantCount),
      );
    }).toList();
  }

  List<BedModel> getAvailableBedsForSlot(
    List<String> selectedDays,
    String selectedShift,
  ) {
    final remoteBeds = state.availableBeds[selectedShift];
    if (remoteBeds != null) return remoteBeds;
    final weekdays = selectedDays.map(_weekdayNumber).toSet();
    final bookedBedIds = state.appointments
        .where(
          (appointment) =>
              appointment.shift == selectedShift &&
              appointment.weekdays.any(weekdays.contains),
        )
        .map((appointment) => appointment.bedId)
        .whereType<String>()
        .toSet();
    return _ref
        .read(bedMatrixControllerProvider)
        .beds
        .where(
          (bed) =>
              bed.status == BedStatus.vacant &&
              !bookedBedIds.contains(bed.bedId),
        )
        .toList();
  }

  int _weekdayNumber(String day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names.indexOf(day) + 1;
  }

  void reschedule(String id, DateTime startTime, {String? bedId}) {
    state = state.copyWith(
      appointments: [
        for (final appointment in state.appointments)
          appointment.id == id
              ? appointment.copyWith(startTime: startTime, bedId: bedId)
              : appointment,
      ],
    );
  }

  void swapBed(String id, String? bedId) {
    final appointment = state.appointments.firstWhere((item) => item.id == id);
    reschedule(id, appointment.startTime, bedId: bedId);
  }

  void updatePatientDisplay(String patientId, String fullName) {
    state = state.copyWith(
      appointments: [
        for (final appointment in state.appointments)
          appointment.patientId == patientId
              ? appointment.copyWith(patientName: fullName)
              : appointment,
      ],
    );
  }
}

final appointmentControllerProvider =
    StateNotifierProvider<AppointmentController, AppointmentState>(
      (ref) => AppointmentController(ref),
    );
