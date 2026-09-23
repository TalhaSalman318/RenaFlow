enum BedStatus { occupied, sanitizing, vacant, alert }

class BedModel {
  const BedModel({
    required this.bedId,
    required this.status,
    this.patientName,
    this.assignedNurse,
    this.elapsedMinutes,
    this.remainingMinutes,
  });

  final String bedId;
  final BedStatus status;
  final String? patientName;
  final String? assignedNurse;
  final int? elapsedMinutes;
  final int? remainingMinutes;

  BedModel copyWith({
    String? bedId,
    BedStatus? status,
    String? patientName,
    String? assignedNurse,
    int? elapsedMinutes,
    int? remainingMinutes,
    bool clearPatient = false,
    bool clearNurse = false,
    bool clearMetrics = false,
  }) {
    return BedModel(
      bedId: bedId ?? this.bedId,
      status: status ?? this.status,
      patientName: clearPatient ? null : patientName ?? this.patientName,
      assignedNurse: clearNurse ? null : assignedNurse ?? this.assignedNurse,
      elapsedMinutes: clearMetrics
          ? null
          : elapsedMinutes ?? this.elapsedMinutes,
      remainingMinutes: clearMetrics
          ? null
          : remainingMinutes ?? this.remainingMinutes,
    );
  }
}
