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
