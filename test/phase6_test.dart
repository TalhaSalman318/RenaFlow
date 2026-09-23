import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/bed_matrix_controller.dart';
import 'package:rena_flow/controllers/queue_matching_controller.dart';
import 'package:rena_flow/controllers/sanitization_controller.dart';
import 'package:rena_flow/models/queue_patient_model.dart';
import 'package:rena_flow/views/queue_sanitization_view.dart';

void main() {
  test('sorts the queue and assigns its top patient to a vacant bed', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(queueMatchingControllerProvider.notifier);
    final topPatient = container
        .read(queueMatchingControllerProvider)
        .sortedPatients
        .first;

    expect(topPatient.priorityScore, PatientPriority.high);
    final recommendations = await controller.matchBed(topPatient);
    expect(recommendations, isNotEmpty);
    expect(recommendations.first.matchScore, 98);

    controller.assignBed(topPatient, recommendations.first.bedId);

    expect(
      container.read(queueMatchingControllerProvider).waitingPatients,
      hasLength(3),
    );
    expect(
      container
          .read(bedMatrixControllerProvider)
          .beds
          .firstWhere((bed) => bed.bedId == recommendations.first.bedId)
          .patientName,
      topPatient.name,
    );
  });

  test('updates sanitization checklist progress', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(sanitizationControllerProvider.notifier);
    controller.toggleStep('Bed 15', 0);
    final task = container
        .read(sanitizationControllerProvider)
        .firstWhere((item) => item.bedId == 'Bed 15');

    expect(task.isUvSterilized, isTrue);
    expect(task.currentStepIndex, 1);
  });

  testWidgets('renders queue and sanitization tabs', (tester) async {
    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(child: MaterialApp(home: QueueSanitizationView())),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Queue matching'), findsOneWidget);
    expect(find.text('Sanitization'), findsOneWidget);
    expect(find.text('Lena Williams'), findsOneWidget);

    await tester.tap(find.text('Sanitization'));
    await tester.pumpAndSettle();
    expect(find.text('Auto-sanitization turnaround'), findsOneWidget);
    expect(find.text('Bed 13'), findsOneWidget);
  });
}
