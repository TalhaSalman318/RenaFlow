import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/dashboard_controller.dart';
import 'package:rena_flow/controllers/ride_alert_controller.dart';

void main() {
  test('dashboard session starts with live dialysis data', () {
    final controller = DashboardController();

    expect(controller.state.completionPercentage, greaterThan(0));
    expect(controller.state.heartRate, 72);
    expect(controller.state.bloodPressure, '128/78');

    controller.dispose();
  });

  test('ride alert confirms pickup', () {
    final controller = RideAlertController();

    expect(controller.state.ride.isConfirmed, isFalse);
    expect(controller.state.remainingSeconds, greaterThan(0));

    controller.confirmPickup();

    expect(controller.state.ride.isConfirmed, isTrue);
    controller.dispose();
  });
}
