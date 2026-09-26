import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bed_model.dart';
import '../services/appointment_service.dart';
import '../services/bed_service.dart';

enum BedMatrixFilter { all, occupied, vacant }

class BedMatrixState {
  const BedMatrixState({required this.beds, this.filter = BedMatrixFilter.all});

  final List<BedModel> beds;
  final BedMatrixFilter filter;

  List<BedModel> get visibleBeds {
    return beds.where((bed) {
      return switch (filter) {
        BedMatrixFilter.all => true,
        BedMatrixFilter.occupied => bed.status != BedStatus.vacant,
        BedMatrixFilter.vacant => bed.status == BedStatus.vacant,
      };
    }).toList();
  }

  int get occupiedCount =>
      beds.where((bed) => bed.status != BedStatus.vacant).length;

  int get vacantCount =>
      beds.where((bed) => bed.status == BedStatus.vacant).length;

  BedMatrixState copyWith({List<BedModel>? beds, BedMatrixFilter? filter}) {
    return BedMatrixState(
      beds: beds ?? this.beds,
      filter: filter ?? this.filter,
    );
  }
}

class BedMatrixController extends StateNotifier<BedMatrixState> {
  BedMatrixController([this._ref]) : super(BedMatrixState(beds: _initialBeds)) {
    load();
  }

  final Ref? _ref;

  Future<void> load() async {
    await fetchBedMatrix();
  }

  Future<void> fetchBedMatrix() async {
    if (_ref == null) return;
    try {
      final beds = await _ref.read(bedServiceProvider).fetchMatrix();
      if (mounted) state = state.copyWith(beds: beds);
    } catch (_) {}
  }

  Future<void> schedulePatient({
    required String bedId,
    required String patientId,
    required List<int> selectedDays,
    required String shift,
  }) async {
    final shiftName = switch (shift.toLowerCase()) {
      'morning' => 'Morning',
      'afternoon' => 'Afternoon',
      'evening' => 'Evening',
      _ => throw ArgumentError.value(shift, 'shift', 'Unknown dialysis shift'),
    };
    final timeRange = switch (shiftName) {
      'Morning' => ('08:00', '12:00'),
      'Afternoon' => ('13:00', '17:00'),
      _ => ('18:00', '22:00'),
    };

    await _ref!
        .read(appointmentServiceProvider)
        .schedule(
          patientId: patientId,
          bedId: bedId,
          selectedDays: selectedDays,
          shift: shiftName,
          startTimeLocal: timeRange.$1,
          endTimeLocal: timeRange.$2,
        );
    await fetchBedMatrix();
  }

  Future<void> unassignSchedule({required String scheduleId}) async {
    await _ref!
        .read(appointmentServiceProvider)
        .unassign(scheduleId: scheduleId);
    await fetchBedMatrix();
  }

  void applyRemoteBed(Map<String, dynamic> json) {
    final remote = BedModel.fromJson(json);
    _updateBed(remote.bedId, (_) => remote);
  }

  static final _initialBeds = List<BedModel>.generate(50, (index) {
    final bedNumber = index + 1;
    if (bedNumber <= 12) {
      return BedModel(
        bedId: 'Bed $bedNumber',
        status: bedNumber == 4 ? BedStatus.alert : BedStatus.occupied,
        assignedNurse: null,
        elapsedMinutes: 65 + (bedNumber * 4),
        remainingMinutes: 240 - (65 + (bedNumber * 4)),
      );
    }
    return BedModel(bedId: 'Bed $bedNumber', status: BedStatus.vacant);
  });

  void setFilter(BedMatrixFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setVacant(String bedId) {
    _updateBed(
      bedId,
      (bed) => bed.copyWith(
        status: BedStatus.vacant,
        clearPatient: true,
        clearNurse: true,
        clearMetrics: true,
      ),
    );
  }

  void triggerAlert(String bedId) {
    _updateBed(bedId, (bed) => bed.copyWith(status: BedStatus.alert));
  }

  void setActive(String bedId) {
    _updateBed(bedId, (bed) => bed.copyWith(status: BedStatus.occupied));
  }

  void assignPatient({
    required String bedId,
    required String patientName,
    required String assignedNurse,
    String? shift,
  }) {
    final updatedShiftSlots = state.beds
        .firstWhere(
          (bed) => bed.bedId == bedId,
          orElse: () => const BedModel(bedId: '', status: BedStatus.vacant),
        )
        .shiftSlots
        .map((slot) {
          if (shift != null && slot.shift == shift) {
            return BedShiftSlot(
              shift: slot.shift,
              label: slot.label,
              timeRange: slot.timeRange,
              status: 'assigned',
              patientName: patientName.trim(),
              medicalId: 'PT-NEW',
              days: const ['Mon'],
            );
          }
          return slot;
        })
        .toList();

    _updateBed(
      bedId,
      (bed) => bed.copyWith(
        status: BedStatus.occupied,
        patientName: patientName.trim(),
        assignedNurse: assignedNurse.trim(),
        elapsedMinutes: 0,
        remainingMinutes: 240,
        shiftSlots: updatedShiftSlots.isNotEmpty
            ? updatedShiftSlots
            : bed.shiftSlots,
      ),
    );
  }

  void _updateBed(String bedId, BedModel Function(BedModel bed) update) {
    final index = state.beds.indexWhere((bed) => bed.bedId == bedId);
    if (index < 0) return;
    final beds = [...state.beds];
    beds[index] = update(beds[index]);
    state = state.copyWith(beds: beds);
  }
}

final bedMatrixControllerProvider =
    StateNotifierProvider<BedMatrixController, BedMatrixState>(
      (ref) => BedMatrixController(ref),
    );
