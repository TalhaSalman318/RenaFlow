class SanitizationTaskModel {
  const SanitizationTaskModel({
    required this.bedId,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.isUvSterilized,
    required this.isFilterFlushed,
    required this.isLineChanged,
    required this.remainingTimeSeconds,
  });

  final String bedId;
  final int currentStepIndex;
  final int totalSteps;
  final bool isUvSterilized;
  final bool isFilterFlushed;
  final bool isLineChanged;
  final int remainingTimeSeconds;

  double get progress => totalSteps == 0 ? 0 : currentStepIndex / totalSteps;

  SanitizationTaskModel copyWith({
    int? currentStepIndex,
    bool? isUvSterilized,
    bool? isFilterFlushed,
    bool? isLineChanged,
    int? remainingTimeSeconds,
  }) {
    return SanitizationTaskModel(
      bedId: bedId,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps,
      isUvSterilized: isUvSterilized ?? this.isUvSterilized,
      isFilterFlushed: isFilterFlushed ?? this.isFilterFlushed,
      isLineChanged: isLineChanged ?? this.isLineChanged,
      remainingTimeSeconds: remainingTimeSeconds ?? this.remainingTimeSeconds,
    );
  }
}
