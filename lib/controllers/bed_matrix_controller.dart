import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bed_model.dart';

enum BedMatrixFilter { all, occupied, vacant, sanitizing }

class BedMatrixState {
  const BedMatrixState({required this.beds, this.filter = BedMatrixFilter.all});

  final List<BedModel> beds;
  final BedMatrixFilter filter;

  List<BedModel> get visibleBeds {
    return beds.where((bed) {
      return switch (filter) {
        BedMatrixFilter.all => true,
        BedMatrixFilter.occupied =>
          bed.status == BedStatus.occupied || bed.status == BedStatus.alert,
        BedMatrixFilter.vacant => bed.status == BedStatus.vacant,
        BedMatrixFilter.sanitizing => bed.status == BedStatus.sanitizing,
      };
    }).toList();
  }

  int get occupiedCount =>
      beds.where((bed) => bed.status == BedStatus.occupied).length;

  int get vacantCount =>
      beds.where((bed) => bed.status == BedStatus.vacant).length;

  int get sanitizingCount =>
      beds.where((bed) => bed.status == BedStatus.sanitizing).length;

  BedMatrixState copyWith({List<BedModel>? beds, BedMatrixFilter? filter}) {
    return BedMatrixState(
      beds: beds ?? this.beds,
      filter: filter ?? this.filter,
    );
  }
}

class BedMatrixController extends StateNotifier<BedMatrixState> {
  BedMatrixController() : super(BedMatrixState(beds: _initialBeds));

  static final _initialBeds = List<BedModel>.generate(50, (index) {
    final bedNumber = index + 1;
    if (bedNumber <= 12) {
      return BedModel(
        bedId: 'Bed $bedNumber',
        status: bedNumber == 4 ? BedStatus.alert : BedStatus.occupied,
        patientName: bedNumber == 4 ? 'Samuel Okafor' : 'Patient $bedNumber',
        assignedNurse: 'Nurse ${((bedNumber - 1) % 4) + 1}',
        elapsedMinutes: 65 + (bedNumber * 4),
        remainingMinutes: 240 - (65 + (bedNumber * 4)),
      );
    }
    if (bedNumber <= 17) {
      return BedModel(bedId: 'Bed $bedNumber', status: BedStatus.sanitizing);
    }
    return BedModel(bedId: 'Bed $bedNumber', status: BedStatus.vacant);
  });

  void setFilter(BedMatrixFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSanitizing(String bedId) {
    _updateBed(
      bedId,
      (bed) => bed.copyWith(
        status: BedStatus.sanitizing,
        clearPatient: true,
        clearNurse: true,
        clearMetrics: true,
      ),
    );
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
  }) {
    _updateBed(
      bedId,
      (bed) => bed.copyWith(
        status: BedStatus.occupied,
        patientName: patientName.trim(),
        assignedNurse: assignedNurse.trim(),
        elapsedMinutes: 0,
        remainingMinutes: 240,
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
      (ref) => BedMatrixController(),
    );
