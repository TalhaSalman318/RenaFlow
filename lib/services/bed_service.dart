import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bed_model.dart';
import 'api_service.dart';

class BedService {
  BedService(this._api);
  final ApiService _api;

  Future<List<BedModel>> fetchMatrix() async {
    final data = await _api.get('/beds/matrix');
    final raw = data['beds'] ?? data['matrix'] ?? data;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => BedModel.fromJson(item)).toList();
  }

  Future<BedModel> updateStatus(
    String bedId,
    String status, {
    String? alertReason,
    String? patientId,
  }) async {
    final apiBedId = bedId.replaceFirst('Bed ', '');
    final data = await _api.post('/beds/$apiBedId/status', {
      'status': status,
      if (alertReason != null) 'alertReason': alertReason,
      if (patientId != null) 'patientId': patientId,
    });
    return BedModel.fromJson(data['bed'] as Map);
  }
}

final bedServiceProvider = Provider<BedService>(
  (ref) => BedService(ref.watch(apiServiceProvider)),
);
