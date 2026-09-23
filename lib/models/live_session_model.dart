class LiveSessionModel {
  const LiveSessionModel({
    required this.elapsedTime,
    required this.totalDuration,
    required this.ufRate,
    required this.bloodFlowRate,
    required this.heartRate,
    required this.bloodPressure,
    required this.completionPercentage,
  });

  final Duration elapsedTime;
  final Duration totalDuration;
  final double ufRate;
  final int bloodFlowRate;
  final int heartRate;
  final String bloodPressure;
  final double completionPercentage;

  LiveSessionModel copyWith({
    Duration? elapsedTime,
    Duration? totalDuration,
    double? ufRate,
    int? bloodFlowRate,
    int? heartRate,
    String? bloodPressure,
    double? completionPercentage,
  }) {
    return LiveSessionModel(
      elapsedTime: elapsedTime ?? this.elapsedTime,
      totalDuration: totalDuration ?? this.totalDuration,
      ufRate: ufRate ?? this.ufRate,
      bloodFlowRate: bloodFlowRate ?? this.bloodFlowRate,
      heartRate: heartRate ?? this.heartRate,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }
}
