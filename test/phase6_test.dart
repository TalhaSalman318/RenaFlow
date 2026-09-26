import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/bed_matrix_controller.dart';
import 'package:rena_flow/controllers/admin_patient_controller.dart';
import 'package:rena_flow/controllers/queue_matching_controller.dart';
import 'package:rena_flow/controllers/sanitization_controller.dart';
import 'package:rena_flow/controllers/session_timer_controller.dart';
import 'package:rena_flow/models/patient_model.dart';
import 'package:rena_flow/models/queue_patient_model.dart';
import 'package:rena_flow/views/patient_detail_management_screen.dart';
import 'package:rena_flow/views/queue_sanitization_view.dart';

void main() {
  test('ranks candidates and assigns a recommended vacant bed', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const candidates = QueueMatchingState(
      waitingPatients: [
        QueuePatientModel(
          patientId: 'low',
          name: 'Low Priority',
          priorityScore: PatientPriority.low,
          transportEtaMinutes: 15,
          vascularAccessType: 'Catheter',
        ),
        QueuePatientModel(
          patientId: 'high',
          name: 'High Priority',
          priorityScore: PatientPriority.high,
          transportEtaMinutes: 5,
          vascularAccessType: 'AV Fistula',
        ),
      ],
    );
    final controller = container.read(queueMatchingControllerProvider.notifier);
    final topPatient = candidates.sortedPatients.first;

    expect(topPatient.priorityScore, PatientPriority.high);
    final recommendations = await controller.matchBed(topPatient);
    expect(recommendations, isNotEmpty);
    expect(recommendations.first.matchScore, 98);

    controller.assignBed(topPatient, recommendations.first.bedId);

    expect(
      container.read(queueMatchingControllerProvider).recentlyAssignedPatientId,
      topPatient.patientId,
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

  test('same-session start events do not roll back elapsed timer state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionTimerControllerProvider.notifier);

    controller.applyRemoteTick({
      'bedId': 'Bed 8',
      'patientId': 'patient-1',
      'patientMedicalId': 'PT-2026-0001',
      'sessionId': 'session-1',
      'status': 'active',
      'durationMinutes': 240,
      'elapsedSeconds': 18,
      'remainingSeconds': 14382,
    });
    controller.applyRemoteTick({
      'bedId': 'Bed 8',
      'patientId': 'patient-1',
      'patientMedicalId': 'PT-2026-0001',
      'sessionId': 'session-1',
      'status': 'active',
      'durationMinutes': 240,
      'elapsedSeconds': 0,
      'remainingSeconds': 14400,
    });

    final timer = container.read(sessionTimerControllerProvider)['Bed 8'];
    expect(timer?.patientId, 'patient-1');
    expect(timer?.elapsedSeconds, 18);
    expect(timer?.remainingSeconds, 14382);

    controller.applyRemoteTick({
      'bedId': 'Bed 8',
      'patientId': 'patient-1',
      'patientMedicalId': 'PT-2026-0001',
      'sessionId': 'session-1',
      'status': 'paused',
      'elapsedSeconds': 20,
      'remainingSeconds': 14380,
    });
    controller.applyRemoteTick({
      'bedId': 'Bed 8',
      'patientId': 'patient-1',
      'patientMedicalId': 'PT-2026-0001',
      'sessionId': 'session-1',
      'status': 'active',
      'elapsedSeconds': 0,
      'remainingSeconds': 14400,
    });
    expect(
      container.read(sessionTimerControllerProvider)['Bed 8']?.status,
      SessionTimerStatus.paused,
    );
  });

  test('keeps concurrent dialysis timers isolated by bed and patient', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionTimerControllerProvider.notifier);

    controller.applyRemoteTick({
      'bedId': 'Bed 8',
      'patientId': 'patient-a',
      'patientMedicalId': 'PT-2026-0001',
      'sessionId': 'session-a',
      'status': 'active',
      'durationMinutes': 240,
      'elapsedSeconds': 60,
      'remainingSeconds': 14340,
    });
    controller.applyRemoteTick({
      'bedId': 'Bed 9',
      'patientId': 'patient-b',
      'patientMedicalId': 'PT-2026-0002',
      'sessionId': 'session-b',
      'status': 'active',
      'durationMinutes': 180,
      'elapsedSeconds': 120,
      'remainingSeconds': 10680,
    });

    final timers = container.read(sessionTimerControllerProvider);
    expect(timers, hasLength(2));
    expect(timers['Bed 8']?.patientId, 'patient-a');
    expect(timers['Bed 8']?.remainingSeconds, 14340);
    expect(timers['Bed 9']?.patientId, 'patient-b');
    expect(timers['Bed 9']?.remainingSeconds, 10680);
  });

  testWidgets('patient flow card opens patient management', (tester) async {
    const patient = PatientModel(
      id: 'patient-1',
      name: 'Hasan Khan',
      age: 42,
      gender: 'Male',
      medicalId: 'RF-001',
      dryWeight: 70,
      vascularAccess: 'AV Fistula',
      baselineBp: '120/80',
      nephrologist: 'Dr. Ali',
      emergencyContact: 'Sara Khan',
      assignedBedId: 'Bed 20',
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        child: ProviderScope(
          overrides: [
            adminPatientControllerProvider.overrideWith(
              (ref) => _TestAdminPatientController(ref, patient),
            ),
          ],
          child: const MaterialApp(home: QueueSanitizationView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hasan Khan'));
    await tester.pumpAndSettle();

    expect(find.byType(PatientDetailManagementScreen), findsOneWidget);
    expect(find.text('Medical ID  RF-001'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dialysis session'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Dialysis session'), findsOneWidget);
  });

  testWidgets('hydrates paused sessions and enables resume and stop', (
    tester,
  ) async {
    const patient = PatientModel(
      id: 'patient-2',
      name: 'Shees Ali',
      age: 38,
      gender: 'Male',
      medicalId: 'RF-002',
      dryWeight: 72,
      vascularAccess: 'AV Fistula',
      baselineBp: '122/82',
      nephrologist: 'Dr. Ali',
      emergencyContact: 'Care team',
      assignedBedId: 'Bed 20',
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        child: ProviderScope(
          overrides: [
            sessionTimerControllerProvider.overrideWith(
              (ref) => _PausedSessionTimerController(ref),
            ),
          ],
          child: const MaterialApp(
            home: PatientDetailManagementScreen(patient: patient),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dialysis session'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(find.text('Session paused'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Start Dialysis'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Resume'))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Stop Session'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('renders Patient Flow search and profiles directly', (
    tester,
  ) async {
    const lena = PatientModel(
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
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        child: ProviderScope(
          overrides: [
            adminPatientControllerProvider.overrideWith(
              (ref) => _TestAdminPatientController(ref, lena),
            ),
          ],
          child: const MaterialApp(home: QueueSanitizationView()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Patient flow'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Search patients by name or Medical ID',
      ),
      findsOneWidget,
    );
    expect(find.text('Lena Williams'), findsOneWidget);
  });
}

class _TestAdminPatientController extends AdminPatientController {
  _TestAdminPatientController(Ref ref, PatientModel patient) : super(ref) {
    state = state.copyWith(patients: [patient]);
  }

  @override
  Future<void> loadPatients() async {}
}

class _PausedSessionTimerController extends SessionTimerController {
  _PausedSessionTimerController(Ref ref) : super(ref);

  @override
  Future<void> hydratePatientSession({
    required String patientId,
    required String patientMedicalId,
    String? assignedBedId,
  }) async {
    applyRemoteTick({
      'bedId': assignedBedId ?? 'Bed 20',
      'patientMedicalId': patientMedicalId,
      'status': 'paused',
      'elapsedSeconds': 1800,
      'remainingSeconds': 12600,
      'totalDurationMinutes': 240,
    });
  }
}
