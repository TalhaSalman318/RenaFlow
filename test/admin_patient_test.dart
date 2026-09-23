import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/admin_patient_controller.dart';
import 'package:rena_flow/controllers/bed_matrix_controller.dart';
import 'package:rena_flow/models/patient_model.dart';
import 'package:rena_flow/views/admin/admin_patient_list_view.dart';

void main() {
  test('filters, adds, assigns, and unassigns patient records', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(adminPatientControllerProvider.notifier);

    controller.setSearchQuery('Lena');
    expect(
      container.read(adminPatientControllerProvider).filteredPatients,
      hasLength(1),
    );

    final patient = const PatientModel(
      id: 'p-test',
      name: 'Jordan Brooks',
      age: 51,
      gender: 'Other',
      medicalId: 'RF-PT-9999',
      dryWeight: 70,
      vascularAccess: 'Catheter',
      baselineBp: '126/80',
      nephrologist: 'Dr. Lee',
      emergencyContact: 'Care team',
    );
    await controller.addPatient(patient);
    expect(
      container.read(adminPatientControllerProvider).patients,
      hasLength(4),
    );

    expect(controller.assignToBed('p-test', 'Bed 18'), isTrue);
    expect(
      container
          .read(adminPatientControllerProvider)
          .patients
          .last
          .assignedBedId,
      'Bed 18',
    );
    expect(
      container
          .read(bedMatrixControllerProvider)
          .beds
          .firstWhere((bed) => bed.bedId == 'Bed 18')
          .patientName,
      'Jordan Brooks',
    );

    controller.unassignFromBed('p-test');
    expect(
      container
          .read(adminPatientControllerProvider)
          .patients
          .last
          .assignedBedId,
      isNull,
    );
  });

  testWidgets('renders admin patient management list', (tester) async {
    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(child: MaterialApp(home: AdminPatientListView())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Patient management'), findsOneWidget);
    expect(find.text('Samuel Okafor'), findsOneWidget);
    expect(find.text('Add patient'), findsOneWidget);
  });
}
