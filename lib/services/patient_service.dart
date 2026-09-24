import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_model.dart';
import 'api_service.dart';

class PatientService {
  PatientService(this._api);
  final ApiService _api;

  Future<PatientCreationResult> createPatient({
    required String fullName,
    required String phone,
    required String gender,
    required String bloodGroup,
    required String password,
  }) async {
    final data = await _api.post('/patients', {
      'fullName': fullName,
      'phone': phone,
      'gender': gender.toLowerCase(),
      'bloodGroup': bloodGroup,
      'password': password,
    });
    final patient = data['patient'] is Map
        ? PatientModel.fromJson(data['patient'] as Map)
        : null;
    return PatientCreationResult(
      medicalId: data['medicalId'].toString(),
      password: data['password'].toString(),
      patient: patient,
    );
  }

  Future<List<PatientModel>> fetchPatients() async {
    final data = await _api.get('/patients');
    final raw = data['patients'] ?? data['items'] ?? data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => PatientModel.fromJson(item))
        .toList();
  }
}

class PatientCreationResult {
  const PatientCreationResult({
    required this.medicalId,
    required this.password,
    this.patient,
  });
  final String medicalId;
  final String password;
  final PatientModel? patient;
}

final patientServiceProvider = Provider<PatientService>(
  (ref) => PatientService(ref.watch(apiServiceProvider)),
);
