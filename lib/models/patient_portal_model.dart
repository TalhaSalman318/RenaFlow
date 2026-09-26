class PatientPortalSchedule {
  const PatientPortalSchedule({
    required this.shift,
    required this.selectedDays,
    required this.startTime,
    required this.endTime,
    required this.bedId,
  });

  final String shift;
  final List<int> selectedDays;
  final String startTime;
  final String endTime;
  final String? bedId;

  String get assignedDays => selectedDays.map(_dayName).join(', ');

  factory PatientPortalSchedule.fromJson(Map<dynamic, dynamic> json) {
    final bed = json['bedId'];
    final bedNumber = bed is Map ? bed['bedNumber'] : null;
    return PatientPortalSchedule(
      shift: json['shift']?.toString() ?? 'Dialysis',
      selectedDays: (json['selectedDays'] as List<dynamic>? ?? const [])
          .map((day) => day is num ? day.toInt() : int.tryParse('$day') ?? 0)
          .where((day) => day >= 1 && day <= 7)
          .toList(),
      startTime: json['startTimeLocal']?.toString() ?? '',
      endTime: json['endTimeLocal']?.toString() ?? '',
      bedId: bedNumber == null ? null : 'Bed $bedNumber',
    );
  }

  static String _dayName(int day) => switch (day) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    7 => 'Sun',
    _ => '',
  };
}

class PatientSessionHistoryItem {
  const PatientSessionHistoryItem({
    required this.sessionId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.bedId,
    required this.elapsedSeconds,
  });

  final String sessionId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final String? bedId;
  final int elapsedSeconds;

  String get statusLabel => switch (status.toLowerCase()) {
    'completed' => 'Completed',
    'paused' => 'Paused',
    'active' || 'running' || 'delayed' => 'In Progress',
    _ => status,
  };

  factory PatientSessionHistoryItem.fromJson(Map<dynamic, dynamic> json) {
    return PatientSessionHistoryItem(
      sessionId: json['sessionId']?.toString() ?? json['_id']?.toString() ?? '',
      startTime: _date(json['startTime'] ?? json['startedAt']),
      endTime: _date(json['endTime'] ?? json['endedAt']),
      status: json['status']?.toString() ?? 'unknown',
      bedId: json['bedId']?.toString(),
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
}
