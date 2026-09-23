enum SessionStatus { completed, interrupted }

class SessionLogModel {
  const SessionLogModel({
    required this.sessionId,
    required this.date,
    required this.durationMinutes,
    required this.preWeight,
    required this.postWeight,
    required this.fluidRemoved,
    required this.ktVScore,
    required this.clinicLocation,
    required this.status,
  });

  final String sessionId;
  final DateTime date;
  final int durationMinutes;
  final double preWeight;
  final double postWeight;
  final double fluidRemoved;
  final double ktVScore;
  final String clinicLocation;
  final SessionStatus status;
}
