enum AppointmentFrequency { twiceWeekly, threeTimesWeekly }

class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.startTime,
    required this.bedId,
    required this.frequency,
    required this.weekdays,
    this.shift = 'Morning · 08:00 AM - 12:00 PM',
  });

  final String id;
  final String patientId;
  final String patientName;
  final DateTime startTime;
  final String? bedId;
  final AppointmentFrequency frequency;
  final List<int> weekdays;
  final String shift;

  factory AppointmentModel.fromJson(Map<dynamic, dynamic> json) {
    final start =
        DateTime.tryParse(json['startsAt']?.toString() ?? '') ?? DateTime.now();
    final shiftName = json['shift']?.toString() ?? 'morning';
    return AppointmentModel(
      id: (json['_id'] ?? json['id']).toString(),
      patientId: json['patientId'].toString(),
      patientName: (json['patientName'] ?? 'RenalFlow Patient').toString(),
      startTime: start,
      bedId: json['bedId']?.toString(),
      frequency: AppointmentFrequency.threeTimesWeekly,
      weekdays: <int>[start.weekday],
      shift: shiftName,
    );
  }

  AppointmentModel copyWith({DateTime? startTime, String? bedId}) {
    return AppointmentModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      startTime: startTime ?? this.startTime,
      bedId: bedId ?? this.bedId,
      frequency: frequency,
      weekdays: weekdays,
      shift: shift,
    );
  }
}
