import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_portal_model.dart';
import '../models/patient_profile_model.dart';
import 'api_service.dart';

class PatientPortalSnapshot {
  const PatientPortalSnapshot({required this.profile, required this.schedules});

  final PatientProfileModel profile;
  final List<PatientPortalSchedule> schedules;
}

class PatientPortalService {
  PatientPortalService(this._api);

  final ApiService _api;

  Future<PatientPortalSnapshot> fetchPortal() async {
    final data = await _api.get('/patients/me');
    final rawPatient = data['patient'];
    if (rawPatient is! Map) {
      throw const ApiException('The patient profile was not returned.');
    }
    final patient = rawPatient.cast<String, dynamic>();
    final schedules = (patient['recurringSchedules'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map(PatientPortalSchedule.fromJson)
        .toList();
    return PatientPortalSnapshot(
      profile: PatientProfileModel.fromJson(patient),
      schedules: schedules,
    );
  }

  Future<List<PatientSessionHistoryItem>> fetchSessionHistory(
    String patientId,
  ) async {
    final data = await _api.get(
      '/sessions/patient/${Uri.encodeComponent(patientId)}',
    );
    return (data['sessions'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map(PatientSessionHistoryItem.fromJson)
        .toList();
  }
}

final patientPortalServiceProvider = Provider<PatientPortalService>(
  (ref) => PatientPortalService(ref.watch(apiServiceProvider)),
);
