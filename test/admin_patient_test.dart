import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/admin_patient_controller.dart';
import 'package:rena_flow/controllers/bed_matrix_controller.dart';
import 'package:rena_flow/models/patient_model.dart';
import 'package:rena_flow/views/admin/admin_patient_list_view.dart';

void main() {
  test('filters, assigns, and unassigns patient records', () async {
    final container = ProviderContainer(
      overrides: [
        adminPatientControllerProvider.overrideWith(
          (ref) => _TestAdminPatientController(ref, [_lena, _jordan]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(adminPatientControllerProvider.notifier);

    controller.setSearchQuery('Lena');
    expect(
      container.read(adminPatientControllerProvider).filteredPatients,
      hasLength(1),
    );

    controller.setSearchQuery('');
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
      ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(
          overrides: [
            adminPatientControllerProvider.overrideWith(
              (ref) => _TestAdminPatientController(ref, [_samuel]),
            ),
          ],
          child: const MaterialApp(home: AdminPatientListView()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Patient management'), findsOneWidget);
    expect(find.text('Samuel Okafor'), findsOneWidget);
    expect(find.text('Add patient'), findsOneWidget);
  });
}

const _lena = PatientModel(
  id: 'p-lena',
  name: 'Lena Williams',
  age: 42,
  gender: 'Female',
  medicalId: 'RF-PT-1001',
  dryWeight: 65,
  vascularAccess: 'AV Fistula',
  baselineBp: '120/80',
  nephrologist: 'Dr. Lee',
  emergencyContact: 'Care team',
);

const _jordan = PatientModel(
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

const _samuel = PatientModel(
  id: 'p-samuel',
  name: 'Samuel Okafor',
  age: 47,
  gender: 'Male',
  medicalId: 'RF-PT-1022',
  dryWeight: 72,
  vascularAccess: 'AV Fistula',
  baselineBp: '124/82',
  nephrologist: 'Dr. Lee',
  emergencyContact: 'Care team',
);

class _TestAdminPatientController extends AdminPatientController {
  _TestAdminPatientController(Ref ref, List<PatientModel> patients)
    : super(ref) {
    state = state.copyWith(patients: patients);
  }

  @override
  Future<void> loadPatients() async {}
}
