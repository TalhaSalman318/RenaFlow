import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/bed_model.dart';
import '../models/patient_model.dart';
import 'bed_matrix_controller.dart';
import '../services/patient_service.dart';

class AdminPatientState {
  const AdminPatientState({
    required this.patients,
    this.searchQuery = '',
    this.isSaving = false,
  });

  final List<PatientModel> patients;
  final String searchQuery;
  final bool isSaving;

  List<PatientModel> get filteredPatients {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return patients;
    return patients.where((patient) {
      return patient.name.toLowerCase().contains(query) ||
          patient.medicalId.toLowerCase().contains(query);
    }).toList();
  }

  AdminPatientState copyWith({
    List<PatientModel>? patients,
    String? searchQuery,
    bool? isSaving,
  }) {
    return AdminPatientState(
      patients: patients ?? this.patients,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class AdminPatientController extends StateNotifier<AdminPatientState> {
  AdminPatientController(this._ref)
    : super(const AdminPatientState(patients: [])) {
    unawaited(loadPatients());
  }

  final Ref _ref;

  Future<void> loadPatients() async {
    try {
      final patients = await _ref.read(patientServiceProvider).fetchPatients();
      if (mounted) state = state.copyWith(patients: patients);
    } catch (_) {}
  }

  Future<void> refresh() => loadPatients();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<PatientCreationResult> createPatient({
    required String fullName,
    required String phone,
    required String gender,
    required String bloodGroup,
    required String password,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final result = await _ref
          .read(patientServiceProvider)
          .createPatient(
            fullName: fullName,
            phone: phone,
            gender: gender,
            bloodGroup: bloodGroup,
            password: password,
          );
      await refresh();
      return result;
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  bool assignToBed(String patientId, String bedId) {
    BedModel? bed;
    for (final item in _ref.read(bedMatrixControllerProvider).beds) {
      if (item.bedId == bedId) {
        bed = item;
        break;
      }
    }
    if (bed == null || bed.status != BedStatus.vacant) return false;
    final patient = state.patients.firstWhere((item) => item.id == patientId);
    _ref
        .read(bedMatrixControllerProvider.notifier)
        .assignPatient(
          bedId: bedId,
          patientName: patient.name,
          assignedNurse: 'Nurse on duty',
        );
    _replace(patient.copyWith(assignedBedId: bedId));
    return true;
  }

  void assignBedToPatient(String patientId, String bedId) {
    final updatedPatients = [
      for (final patient in state.patients)
        if (patient.id == patientId || patient.medicalId == patientId)
          patient.copyWith(assignedBedId: bedId)
        else
          patient,
    ];
    state = state.copyWith(patients: updatedPatients);
  }

  void unassignFromBed(String patientId) {
    final patient = state.patients.firstWhere((item) => item.id == patientId);
    final bedId = patient.assignedBedId;
    if (bedId != null) {
      _ref.read(bedMatrixControllerProvider.notifier).setVacant(bedId);
    }
    _replace(patient.copyWith(clearBed: true));
  }

  void _replace(PatientModel updated) {
    state = state.copyWith(
      patients: [
        for (final patient in state.patients)
          if (patient.id == updated.id) updated else patient,
      ],
    );
  }
}

final adminPatientControllerProvider =
    StateNotifierProvider<AdminPatientController, AdminPatientState>(
      (ref) => AdminPatientController(ref),
    );
