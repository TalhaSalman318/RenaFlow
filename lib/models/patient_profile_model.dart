class PatientProfileModel {
  const PatientProfileModel({
    required this.vascularAccessType,
    required this.dryWeight,
    required this.baselineSystolic,
    required this.baselineDiastolic,
    required this.emergencyContact,
    required this.nephrologistName,
    this.medicalId = 'RF-2026-8941',
    this.id = '',
    this.name = 'RenalFlow Patient',
    this.age = 0,
    this.gender = 'Not provided',
    this.assignedBedId,
    this.phone = '',
    this.bloodGroup = 'Unknown',
  });

  final String vascularAccessType;
  final double dryWeight;
  final int baselineSystolic;
  final int baselineDiastolic;
  final String emergencyContact;
  final String nephrologistName;
  final String medicalId;
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? assignedBedId;
  final String phone;
  final String bloodGroup;

  factory PatientProfileModel.fromJson(Map<dynamic, dynamic> json) {
    final user = json['userId'];
    final bed = json['assignedBedId'];
    final pressure = json['baselineBloodPressure'];
    final emergency = json['emergencyContact'];
    final bedNumber = bed is Map ? bed['bedNumber'] : null;
    final emergencyContact = emergency is Map
        ? '${emergency['name'] ?? ''} · ${emergency['phone'] ?? ''}'
        : emergency?.toString() ?? 'Not provided';

    return PatientProfileModel(
      id: _string(json['_id'] ?? json['id']),
      medicalId: _string(
        json['patientId'] ?? (user is Map ? user['medicalId'] : null),
        fallback: 'Not provided',
      ),
      name: _string(
        json['fullName'] ??
            (user is Map ? user['fullName'] ?? user['displayName'] : null),
        fallback: 'Patient',
      ),
      phone: _string(json['phone'] ?? (user is Map ? user['phone'] : null)),
      bloodGroup: _string(json['bloodGroup'], fallback: 'Unknown'),
      assignedBedId: bedNumber == null ? null : 'Bed $bedNumber',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: _string(json['gender'], fallback: 'Not provided'),
      dryWeight: (json['dryWeightKg'] as num?)?.toDouble() ?? 0,
      vascularAccessType: _string(
        json['vascularAccessType'],
        fallback: 'Not provided',
      ),
      baselineSystolic:
          (pressure is Map ? pressure['systolic'] as num? : null)?.toInt() ?? 0,
      baselineDiastolic:
          (pressure is Map ? pressure['diastolic'] as num? : null)?.toInt() ??
          0,
      emergencyContact: emergencyContact,
      nephrologistName: _string(json['nephrologistName']),
    );
  }

  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
