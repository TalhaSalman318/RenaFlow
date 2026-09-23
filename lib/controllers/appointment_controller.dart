import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../models/bed_model.dart';
import 'bed_matrix_controller.dart';

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
  });

  final List<AppointmentModel> appointments;
  final List<int> selectedDays;
  final String? selectedShift;

  AppointmentState copyWith({
    List<AppointmentModel>? appointments,
    List<int>? selectedDays,
    String? selectedShift,
    bool clearShift = false,
  }) => AppointmentState(
    appointments: appointments ?? this.appointments,
    selectedDays: selectedDays ?? this.selectedDays,
    selectedShift: clearShift ? null : selectedShift ?? this.selectedShift,
  );
}

class AppointmentController extends StateNotifier<AppointmentState> {
  AppointmentController(this._ref) : super(_seedState);

  final Ref _ref;

  static const shifts = [
    'Morning · 08:00 AM - 12:00 PM',
    'Afternoon · 01:00 PM - 05:00 PM',
    'Evening · 06:00 PM - 10:00 PM',
  ];

  static final _seedState = AppointmentState(
    appointments: [
      AppointmentModel(
        id: 'apt-001',
        patientId: 'p-001',
        patientName: 'Samuel Okafor',
        startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        bedId: 'Bed 4',
        frequency: AppointmentFrequency.threeTimesWeekly,
        weekdays: const [1, 3, 5],
        shift: shifts.first,
      ),
    ],
  );

  void addAppointment(AppointmentModel appointment) {
    state = state.copyWith(appointments: [...state.appointments, appointment]);
  }

  void setSelectedDays(List<int> days) {
    state = state.copyWith(selectedDays: [...days]..sort(), clearShift: true);
  }

  void setSelectedShift(String shift) {
    state = state.copyWith(selectedShift: shift);
  }

  List<ShiftAvailability> getAvailableShiftsForDays(List<String> selectedDays) {
    final weekdays = selectedDays.map(_weekdayNumber).toSet();
    final beds = _ref.read(bedMatrixControllerProvider).beds;
    final vacantCount = beds
        .where((bed) => bed.status == BedStatus.vacant)
        .length;
    return shifts.map((shift) {
      final booked = state.appointments.where((appointment) {
        return appointment.shift == shift &&
            appointment.weekdays.any(weekdays.contains);
      }).length;
      return ShiftAvailability(
        shift: shift,
        availableBeds: (vacantCount - booked).clamp(0, vacantCount),
      );
    }).toList();
  }

  List<BedModel> getAvailableBedsForSlot(
    List<String> selectedDays,
    String selectedShift,
  ) {
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
}

final appointmentControllerProvider =
    StateNotifierProvider<AppointmentController, AppointmentState>(
      (ref) => AppointmentController(ref),
    );
