class RideAlertModel {
  const RideAlertModel({
    required this.driverName,
    required this.vehicleNumber,
    required this.etaMinutes,
    required this.pickupTime,
    required this.isConfirmed,
  });

  final String driverName;
  final String vehicleNumber;
  final int etaMinutes;
  final DateTime pickupTime;
  final bool isConfirmed;

  RideAlertModel copyWith({
    String? driverName,
    String? vehicleNumber,
    int? etaMinutes,
    DateTime? pickupTime,
    bool? isConfirmed,
  }) {
    return RideAlertModel(
      driverName: driverName ?? this.driverName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      pickupTime: pickupTime ?? this.pickupTime,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}
