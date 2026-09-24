import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../models/bed_model.dart';
import 'api_service.dart';

class AppointmentAvailability {
  const AppointmentAvailability({required this.shift, required this.beds});
  final String shift;
  final List<BedModel> beds;
  int get availableBeds => beds.length;
}

class AppointmentService {
  AppointmentService(this._api);
  final ApiService _api;

  Future<AppointmentAvailability> availability({
    required List<int> selectedDays,
    required String shift,
  }) async {
    final data = await _api.get(
      '/appointments/availability',
      queryParameters: {'selectedDays': selectedDays.join(','), 'shift': shift},
    );
    final raw = (data['beds'] as List<dynamic>?) ?? const [];
    return AppointmentAvailability(
      shift: shift,
      beds: raw
          .whereType<Map>()
          .map((item) => BedModel.fromJson(item))
          .toList(),
    );
  }

  Future<List<AppointmentModel>> schedule({
    required String patientId,
    required String bedId,
    required List<int> selectedDays,
    required String shift,
    required String startTimeLocal,
    required String endTimeLocal,
  }) async {
    final data = await _api.post('/appointments/schedule', {
      'patientId': patientId,
      'bedId': bedId.replaceFirst('Bed ', ''),
      'selectedDays': selectedDays,
      'shift': shift,
      'startTimeLocal': startTimeLocal,
      'endTimeLocal': endTimeLocal,
    });
    final raw = (data['appointments'] as List<dynamic>?) ?? const [];
    return raw
        .whereType<Map>()
        .map((item) => AppointmentModel.fromJson(item))
        .toList();
  }
}

final appointmentServiceProvider = Provider<AppointmentService>(
  (ref) => AppointmentService(ref.watch(apiServiceProvider)),
);
