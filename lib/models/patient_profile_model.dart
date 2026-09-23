class PatientProfileModel {
  const PatientProfileModel({
    required this.vascularAccessType,
    required this.dryWeight,
    required this.baselineSystolic,
    required this.baselineDiastolic,
    required this.emergencyContact,
    required this.nephrologistName,
    this.medicalId = 'RF-2026-8941',
    this.name = 'RenalFlow Patient',
    this.age = 0,
    this.gender = 'Not provided',
    this.assignedBedId,
  });

  final String vascularAccessType;
  final double dryWeight;
  final int baselineSystolic;
  final int baselineDiastolic;
  final String emergencyContact;
  final String nephrologistName;
  final String medicalId;
  final String name;
  final int age;
  final String gender;
  final String? assignedBedId;
}
