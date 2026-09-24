enum BedStatus { occupied, sanitizing, vacant, alert, delayed }

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

  factory BedModel.fromJson(Map<dynamic, dynamic> json) {
    final number = json['bedNumber'] ?? json['bedId'] ?? json['_id'];
    final patient = json['currentPatientId'];
    final status = switch (json['status'] as String?) {
      'occupied' => BedStatus.occupied,
      'sanitizing' => BedStatus.sanitizing,
      'alert' => BedStatus.alert,
      'delayed' => BedStatus.delayed,
      _ => BedStatus.vacant,
    };
    return BedModel(
      bedId: number.toString().startsWith('Bed ')
          ? number.toString()
          : 'Bed $number',
      status: status,
      patientName: patient is Map ? patient['fullName'] as String? : null,
      assignedNurse: json['assignedNurseId']?.toString(),
      elapsedMinutes: json['elapsedMinutes'] as int?,
      remainingMinutes: json['remainingMinutes'] as int?,
    );
  }

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
