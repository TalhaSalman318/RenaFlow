enum BedStatus { occupied, vacant, alert, delayed }

class BedShiftSlot {
  const BedShiftSlot({
    required this.shift,
    required this.label,
    required this.timeRange,
    this.status = 'vacant',
    this.patientName,
    this.medicalId,
    this.phone,
    this.gender,
    this.bloodGroup,
    this.days = const [],
    this.assignments = const [],
  });

  final String shift;
  final String label;
  final String timeRange;
  final String status;
  final String? patientName;
  final String? medicalId;
  final String? phone;
  final String? gender;
  final String? bloodGroup;
  final List<String> days;
  final List<BedShiftAssignment> assignments;

  bool get isAssigned => status == 'assigned';

  bool hasPatientForDay(int weekday) {
    final dayLabel = _dayShortLabel(weekday);
    if (assignments.isNotEmpty) {
      return assignments.any(
        (assignment) => assignment.days.any(
          (day) => day.toLowerCase() == dayLabel.toLowerCase(),
        ),
      );
    }
    return days.any((day) => day.toLowerCase() == dayLabel.toLowerCase());
  }

  BedShiftAssignment? assignmentForDay(int weekday) {
    final dayLabel = _dayShortLabel(weekday).toLowerCase();
    for (final assignment in assignments) {
      if (assignment.days.any((day) => day.toLowerCase() == dayLabel)) {
        return assignment;
      }
    }
    return assignments.isEmpty && hasPatientForDay(weekday)
        ? BedShiftAssignment(
            patientName: patientName,
            medicalId: medicalId,
            phone: phone,
            gender: gender,
            bloodGroup: bloodGroup,
            days: days,
          )
        : null;
  }

  static String _dayShortLabel(int weekday) => switch (weekday) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    _ => 'Sun',
  };

  factory BedShiftSlot.fromJson(Map<dynamic, dynamic> json) {
    final shift = _canonicalShift((json['shift'] ?? 'Morning').toString());
    final label = (json['label'] ?? _shiftLabel(shift)).toString();
    final timeRange = (json['timeRange'] ?? _shiftTimeRange(shift)).toString();
    final rawDays = json['days'] as List<dynamic>? ?? const [];
    final days = rawDays.map((day) => day.toString()).toList();
    final rawAssignments = json['assignments'] as List<dynamic>? ?? const [];
    final assignments = rawAssignments
        .whereType<Map>()
        .map((assignment) => BedShiftAssignment.fromJson(assignment))
        .toList();

    return BedShiftSlot(
      shift: shift,
      label: label,
      timeRange: timeRange,
      status: (json['status'] ?? 'vacant').toString(),
      patientName: json['patientName']?.toString(),
      medicalId: json['medicalId']?.toString(),
      days: days,
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      assignments: assignments,
    );
  }

  static String _canonicalShift(String shift) => switch (shift.toLowerCase()) {
    'morning' => 'Morning',
    'afternoon' => 'Afternoon',
    _ => 'Evening',
  };

  static String _shiftLabel(String shift) => switch (shift) {
    'Morning' => 'Morning Shift',
    'Afternoon' => 'Afternoon Shift',
    _ => 'Evening Shift',
  };

  static String _shiftTimeRange(String shift) => switch (shift) {
    'Morning' => '08:00 AM - 12:00 PM',
    'Afternoon' => '01:00 PM - 05:00 PM',
    _ => '06:00 PM - 10:00 PM',
  };
}

class BedShiftAssignment {
  const BedShiftAssignment({
    this.scheduleId,
    required this.patientName,
    required this.medicalId,
    required this.phone,
    required this.gender,
    required this.bloodGroup,
    required this.days,
  });

  final String? scheduleId;
  final String? patientName;
  final String? medicalId;
  final String? phone;
  final String? gender;
  final String? bloodGroup;
  final List<String> days;

  factory BedShiftAssignment.fromJson(Map<dynamic, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? const [];
    return BedShiftAssignment(
      scheduleId: json['scheduleId']?.toString(),
      patientName: json['patientName']?.toString(),
      medicalId: json['medicalId']?.toString(),
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      days: rawDays.map((day) => day.toString()).toList(),
    );
  }
}

class BedModel {
  const BedModel({
    required this.bedId,
    required this.status,
    this.patientName,
    this.assignedNurse,
    this.elapsedMinutes,
    this.remainingMinutes,
    this.shiftSlots = const [],
  });

  final String bedId;
  final BedStatus status;
  final String? patientName;
  final String? assignedNurse;
  final int? elapsedMinutes;
  final int? remainingMinutes;
  final List<BedShiftSlot> shiftSlots;

  int get occupiedSlots => shiftSlots.where((slot) => slot.isAssigned).length;
  int get availableSlots => shiftSlots.length - occupiedSlots;

  factory BedModel.fromJson(Map<dynamic, dynamic> json) {
    final number = json['bedNumber'] ?? json['bedId'] ?? json['_id'];
    final patient = json['currentPatientId'];
    final status = switch (json['status'] as String?) {
      'occupied' => BedStatus.occupied,
      'alert' => BedStatus.alert,
      'delayed' => BedStatus.delayed,
      _ => BedStatus.vacant,
    };

    final rawSlots = (json['shiftSlots'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((slot) => BedShiftSlot.fromJson(slot))
        .toList();

    return BedModel(
      bedId: number.toString().startsWith('Bed ')
          ? number.toString()
          : 'Bed $number',
      status: status,
      patientName: patient is Map ? patient['fullName'] as String? : null,
      assignedNurse: json['assignedNurseId']?.toString(),
      elapsedMinutes: json['elapsedMinutes'] as int?,
      remainingMinutes: json['remainingMinutes'] as int?,
      shiftSlots: rawSlots.isEmpty
          ? const [
              BedShiftSlot(
                shift: 'Morning',
                label: 'Morning Shift',
                timeRange: '08:00 AM - 12:00 PM',
              ),
              BedShiftSlot(
                shift: 'Afternoon',
                label: 'Afternoon Shift',
                timeRange: '01:00 PM - 05:00 PM',
              ),
              BedShiftSlot(
                shift: 'Evening',
                label: 'Evening Shift',
                timeRange: '06:00 PM - 10:00 PM',
              ),
            ]
          : rawSlots,
    );
  }

  BedModel copyWith({
    String? bedId,
    BedStatus? status,
    String? patientName,
    String? assignedNurse,
    int? elapsedMinutes,
    int? remainingMinutes,
    List<BedShiftSlot>? shiftSlots,
    bool clearPatient = false,
    bool clearNurse = false,
    bool clearMetrics = false,
  }) {
    return BedModel(
      bedId: bedId ?? this.bedId,
      status: status ?? this.status,
      patientName: clearPatient ? null : patientName ?? this.patientName,
      assignedNurse: clearNurse ? null : assignedNurse ?? this.assignedNurse,
      elapsedMinutes: clearMetrics
          ? null
          : elapsedMinutes ?? this.elapsedMinutes,
      remainingMinutes: clearMetrics
          ? null
          : remainingMinutes ?? this.remainingMinutes,
      shiftSlots: shiftSlots ?? this.shiftSlots,
    );
  }
}
