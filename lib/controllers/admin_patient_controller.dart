import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bed_model.dart';
import '../models/patient_model.dart';
import 'bed_matrix_controller.dart';

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
  AdminPatientController(this._ref) : super(AdminPatientState(patients: _seed));

  final Ref _ref;

  static const _seed = <PatientModel>[
    PatientModel(
      id: 'p-001',
      name: 'Samuel Okafor',
      age: 58,
      gender: 'Male',
      medicalId: 'RF-PT-1042',
      dryWeight: 71.8,
      vascularAccess: 'AV Fistula',
      baselineBp: '128/78',
      nephrologist: 'Dr. Amina Rahman',
      emergencyContact: 'Ada Okafor · +1 555 0101',
      assignedBedId: 'Bed 4',
    ),
    PatientModel(
      id: 'p-002',
      name: 'Lena Williams',
      age: 64,
      gender: 'Female',
      medicalId: 'RF-PT-1077',
      dryWeight: 68.5,
      vascularAccess: 'AV Fistula',
      baselineBp: '132/82',
      nephrologist: 'Dr. Amina Rahman',
      emergencyContact: 'Noah Williams · +1 555 0102',
    ),
    PatientModel(
      id: 'p-003',
      name: 'David Chen',
      age: 46,
      gender: 'Male',
      medicalId: 'RF-PT-1027',
      dryWeight: 74.2,
      vascularAccess: 'Catheter',
      baselineBp: '124/76',
      nephrologist: 'Dr. Marcus Lee',
      emergencyContact: 'Mei Chen · +1 555 0103',
    ),
  ];

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addPatient(PatientModel patient) async {
    state = state.copyWith(isSaving: true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final generatedId = patient.medicalId.trim().isEmpty
        ? 'RF-${DateTime.now().year}-${(1000 + state.patients.length * 731) % 9000}'
        : patient.medicalId.trim();
    final savedPatient = PatientModel(
      id: patient.id,
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      medicalId: generatedId,
      dryWeight: patient.dryWeight,
      vascularAccess: patient.vascularAccess,
      baselineBp: patient.baselineBp,
      nephrologist: patient.nephrologist,
      emergencyContact: patient.emergencyContact,
      assignedBedId: patient.assignedBedId,
    );
    state = state.copyWith(
      patients: [...state.patients, savedPatient],
      isSaving: false,
    );
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
