enum PatientPriority { high, medium, low }

class QueuePatientModel {
  const QueuePatientModel({
    required this.patientId,
    required this.name,
    required this.priorityScore,
    required this.transportEtaMinutes,
    required this.vascularAccessType,
    this.matchedBedId,
  });

  final String patientId;
  final String name;
  final PatientPriority priorityScore;
  final int transportEtaMinutes;
  final String vascularAccessType;
  final String? matchedBedId;
}
