import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/bed_matrix_controller.dart';
import 'package:rena_flow/models/bed_model.dart';
import 'package:rena_flow/views/bed_matrix_view.dart';

void main() {
  test('manages bed filters and quick action mutations', () {
    final controller = BedMatrixController();

    expect(controller.state.beds, hasLength(50));
    expect(controller.state.occupiedCount, 11);
    expect(controller.state.vacantCount, 33);
    expect(controller.state.sanitizingCount, 5);

    controller.setFilter(BedMatrixFilter.sanitizing);
    expect(controller.state.visibleBeds, hasLength(5));

    controller.setFilter(BedMatrixFilter.all);
    controller.setSanitizing('Bed 1');
    expect(controller.state.beds.first.status, BedStatus.sanitizing);

    controller.assignPatient(
      bedId: 'Bed 1',
      patientName: 'Taylor Morgan',
      assignedNurse: 'Nurse on duty',
    );
    expect(controller.state.beds.first.status, BedStatus.occupied);
    expect(controller.state.beds.first.patientName, 'Taylor Morgan');

    controller.setVacant('Bed 1');
    expect(controller.state.beds.first.status, BedStatus.vacant);
    controller.dispose();
  });

  testWidgets('renders the 50-bed matrix and status filters', (tester) async {
    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(child: MaterialApp(home: BedMatrixView())),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Bed matrix'), findsNWidgets(2));
    expect(find.text('Occupied'), findsNWidgets(2));
    expect(find.text('Sanitizing'), findsNWidgets(2));
    expect(find.text('#1'), findsOneWidget);
  });
}
