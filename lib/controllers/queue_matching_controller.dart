import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/bed_matrix_controller.dart';
import '../models/bed_model.dart';
import '../models/queue_patient_model.dart';

class BedRecommendation {
  const BedRecommendation({required this.bedId, required this.matchScore});

  final String bedId;
  final int matchScore;
}

class QueueMatchingState {
  const QueueMatchingState({
    required this.waitingPatients,
    this.isMatching = false,
    this.recentlyAssignedPatientId,
  });

  final List<QueuePatientModel> waitingPatients;
  final bool isMatching;
  final String? recentlyAssignedPatientId;

  List<QueuePatientModel> get sortedPatients {
    final patients = [...waitingPatients];
    patients.sort(
      (first, second) => _priorityValue(
        second.priorityScore,
      ).compareTo(_priorityValue(first.priorityScore)),
    );
    return patients;
  }

  QueueMatchingState copyWith({
    List<QueuePatientModel>? waitingPatients,
    bool? isMatching,
    String? recentlyAssignedPatientId,
    bool clearRecentlyAssigned = false,
  }) {
    return QueueMatchingState(
      waitingPatients: waitingPatients ?? this.waitingPatients,
      isMatching: isMatching ?? this.isMatching,
      recentlyAssignedPatientId: clearRecentlyAssigned
          ? null
          : recentlyAssignedPatientId ?? this.recentlyAssignedPatientId,
    );
  }

  static int _priorityValue(PatientPriority priority) {
    return switch (priority) {
      PatientPriority.high => 3,
      PatientPriority.medium => 2,
      PatientPriority.low => 1,
    };
  }
}

class QueueMatchingController extends StateNotifier<QueueMatchingState> {
  QueueMatchingController(this._ref) : super(_initialState);

  final Ref _ref;

  static const _initialState = QueueMatchingState(waitingPatients: []);

  List<BedRecommendation> recommendationsFor(QueuePatientModel patient) {
    final beds = _ref.read(bedMatrixControllerProvider).beds;
    final vacantBeds = beds.where((bed) => bed.status == BedStatus.vacant);
    return vacantBeds.take(3).toList().asMap().entries.map((entry) {
      final baseScore = patient.vascularAccessType == 'AV Fistula' ? 98 : 95;
      return BedRecommendation(
        bedId: entry.value.bedId,
        matchScore: baseScore - entry.key,
      );
    }).toList();
  }

  Future<List<BedRecommendation>> matchBed(QueuePatientModel patient) async {
    state = state.copyWith(isMatching: true, clearRecentlyAssigned: true);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    final recommendations = recommendationsFor(patient);
    state = state.copyWith(isMatching: false);
    return recommendations;
  }

  void assignBed(QueuePatientModel patient, String bedId) {
    _ref
        .read(bedMatrixControllerProvider.notifier)
        .assignPatient(
          bedId: bedId,
          patientName: patient.name,
          assignedNurse: 'Nurse on duty',
        );
    state = state.copyWith(
      waitingPatients: state.waitingPatients
          .where((item) => item.patientId != patient.patientId)
          .toList(),
      recentlyAssignedPatientId: patient.patientId,
    );
  }
}

final queueMatchingControllerProvider =
    StateNotifierProvider<QueueMatchingController, QueueMatchingState>(
      (ref) => QueueMatchingController(ref),
    );
