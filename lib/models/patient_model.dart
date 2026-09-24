class PatientModel {
  const PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.medicalId,
    required this.dryWeight,
    required this.vascularAccess,
    required this.baselineBp,
    required this.nephrologist,
    required this.emergencyContact,
    this.assignedBedId,
  });

  final String id;
  final String name;
  final int age;
  final String gender;
  final String medicalId;
  final double dryWeight;
  final String vascularAccess;
  final String baselineBp;
  final String nephrologist;
  final String emergencyContact;
  final String? assignedBedId;

  String get uniquePatientId => medicalId;

  factory PatientModel.fromJson(Map<dynamic, dynamic> json) {
    final baseline = json['baselineBloodPressure'];
    final systolic = baseline is Map ? baseline['systolic'] : null;
    final diastolic = baseline is Map ? baseline['diastolic'] : null;
    return PatientModel(
      id: (json['_id'] ?? json['id'] ?? json['patientId']).toString(),
      name: json['fullName'] as String? ?? 'RenalFlow Patient',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? 'Not provided',
      medicalId: json['patientId'] as String? ?? '',
      dryWeight: (json['dryWeightKg'] as num?)?.toDouble() ?? 0,
      vascularAccess: json['vascularAccessType'] as String? ?? 'Other',
      baselineBp: '${systolic ?? 0}/${diastolic ?? 0}',
      nephrologist: json['nephrologistName'] as String? ?? '',
      emergencyContact: _emergencyContact(json['emergencyContact']),
      assignedBedId: _bedId(json['assignedBedId']),
    );
  }

  static String _emergencyContact(Object? value) {
    if (value is Map) return '${value['name'] ?? ''} · ${value['phone'] ?? ''}';
    return value?.toString() ?? '';
  }

  static String? _bedId(Object? value) {
    if (value is Map) {
      final number = value['bedNumber'];
      return number == null ? null : 'Bed $number';
    }
    return value?.toString();
  }

  PatientModel copyWith({String? assignedBedId, bool clearBed = false}) {
    return PatientModel(
      id: id,
      name: name,
      age: age,
      gender: gender,
      medicalId: medicalId,
      dryWeight: dryWeight,
      vascularAccess: vascularAccess,
      baselineBp: baselineBp,
      nephrologist: nephrologist,
      emergencyContact: emergencyContact,
      assignedBedId: clearBed ? null : assignedBedId ?? this.assignedBedId,
    );
  }
}
