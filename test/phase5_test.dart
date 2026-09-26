import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/bed_matrix_controller.dart';
import 'package:rena_flow/models/bed_model.dart';
import 'package:rena_flow/views/bed_matrix_view.dart';

void main() {
  test('uses occupied and vacant filters and quick action mutations', () {
    final controller = BedMatrixController();

    expect(controller.state.beds, hasLength(50));
    expect(controller.state.occupiedCount, 12);
    expect(controller.state.vacantCount, 38);

    controller.setFilter(BedMatrixFilter.occupied);
    expect(controller.state.visibleBeds, hasLength(12));
    controller.setFilter(BedMatrixFilter.vacant);
    expect(controller.state.visibleBeds, hasLength(38));
    expect(controller.state.beds[12].status, BedStatus.vacant);

    controller.setFilter(BedMatrixFilter.all);
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
    expect(find.text('Vacant'), findsNWidgets(2));
    expect(find.text('Sanitizing'), findsNothing);
    expect(find.text('#1'), findsOneWidget);
  });
}
