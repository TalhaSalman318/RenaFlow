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
    this.phone = '',
    this.email = '',
    this.bloodGroup = 'Unknown',
    this.notes = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
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
  final String phone;
  final String email;
  final String bloodGroup;
  final String notes;
  final String emergencyContactName;
  final String emergencyContactPhone;

  String get uniquePatientId => medicalId;
  String get fullName => name;
  String get assignedBed => assignedBedId ?? 'Unassigned';

  factory PatientModel.fromJson(Map<dynamic, dynamic> json) {
    final baseline = json['baselineBloodPressure'];
    final systolic = baseline is Map ? baseline['systolic'] : null;
    final diastolic = baseline is Map ? baseline['diastolic'] : null;
    final contact = json['emergencyContact'];
    final contactName = contact is Map
        ? (contact['name']?.toString() ?? '')
        : '';
    final contactPhone = contact is Map
        ? (contact['phone']?.toString() ?? '')
        : '';
    final user = json['userId'];
    return PatientModel(
      id: _safeString(json['_id'] ?? json['id'] ?? json['patientId']),
      name: _safeString(json['fullName'], fallback: 'Unknown'),
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: _safeString(json['gender'], fallback: 'Not provided'),
      medicalId: _safeString(json['patientId'], fallback: 'N/A'),
      dryWeight: (json['dryWeightKg'] as num?)?.toDouble() ?? 0,
      vascularAccess: json['vascularAccessType'] as String? ?? 'Other',
      baselineBp: '${systolic ?? 0}/${diastolic ?? 0}',
      nephrologist: json['nephrologistName'] as String? ?? '',
      emergencyContact: contact is Map
          ? '$contactName · $contactPhone'
          : _emergencyContact(contact),
      assignedBedId: _bedId(json['assignedBedId']),
      phone: _safeString(json['phone']),
      email: _safeString(user is Map ? user['email'] : json['email']),
      bloodGroup: json['bloodGroup']?.toString() ?? 'Unknown',
      notes: _safeString(json['notes']),
      emergencyContactName: contactName,
      emergencyContactPhone: contactPhone,
    );
  }

  static String _safeString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
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

  PatientModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? bloodGroup,
    String? notes,
    String? emergencyContact,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? assignedBedId,
    bool clearBed = false,
  }) {
    return PatientModel(
      id: id,
      name: name ?? this.name,
      age: age,
      gender: gender,
      medicalId: medicalId,
      dryWeight: dryWeight,
      vascularAccess: vascularAccess,
      baselineBp: baselineBp,
      nephrologist: nephrologist,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      assignedBedId: clearBed ? null : assignedBedId ?? this.assignedBedId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      notes: notes ?? this.notes,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}
