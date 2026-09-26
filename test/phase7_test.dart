import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rena_flow/app/routes/app_router.dart';
import 'package:rena_flow/controllers/auth_controller.dart';
import 'package:rena_flow/controllers/navigation_controller.dart';
import 'package:rena_flow/controllers/patient_portal_controller.dart';
import 'package:rena_flow/controllers/session_timer_controller.dart';
import 'package:rena_flow/main.dart';
import 'package:rena_flow/models/patient_portal_model.dart';
import 'package:rena_flow/models/patient_profile_model.dart';
import 'package:rena_flow/services/api_service.dart';
import 'package:rena_flow/services/patient_portal_service.dart';
import 'package:rena_flow/views/main_shell_view.dart';

void main() {
  test('navigation controller switches roles and resets tabs', () {
    final controller = NavigationController();

    controller.setIndex(2);
    expect(controller.state.activeIndex, 2);

    controller.switchMode(AppMode.adminNurse);
    expect(controller.state.mode, AppMode.adminNurse);
    expect(controller.state.activeIndex, 0);

    controller.toggleMode();
    expect(controller.state.mode, AppMode.patient);
    expect(controller.state.activeIndex, 0);
    controller.dispose();
  });

  testWidgets('app starts on splash and routes to sign in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const RenalFlowApp(),
      ),
    );

    expect(find.text('RenalFlow'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('main shell switches between patient and operations tabs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(home: MainShellView()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('RenalFlow'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    final context = tester.element(find.byType(MainShellView));
    ProviderScope.containerOf(context)
        .read(navigationControllerProvider.notifier)
        .switchMode(AppMode.adminNurse);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bed matrix'), findsNWidgets(2));
    expect(find.text('Beds'), findsOneWidget);
    expect(find.text('Flow'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
    expect(find.text('Analytics'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('patient portal shows personal data schedules and history', (
    tester,
  ) async {
    final profile = PatientProfileModel(
      id: 'profile-1',
      medicalId: 'PT-2026-0001',
      name: 'Jordan Patient',
      phone: '555-0100',
      bloodGroup: 'O+',
      assignedBedId: 'Bed 8',
      age: 40,
      gender: 'Male',
      vascularAccessType: 'Fistula',
      dryWeight: 70,
      baselineSystolic: 120,
      baselineDiastolic: 80,
      emergencyContact: 'Family',
      nephrologistName: 'Care team',
    );
    final portal = PatientPortalState(
      isLoading: false,
      profile: profile,
      schedules: const [
        PatientPortalSchedule(
          shift: 'Morning',
          selectedDays: [1, 3, 5],
          startTime: '08:00',
          endTime: '12:00',
          bedId: 'Bed 8',
        ),
      ],
      sessions: [
        PatientSessionHistoryItem(
          sessionId: 'session-1',
          startTime: DateTime.utc(2026, 9, 20, 8),
          endTime: DateTime.utc(2026, 9, 20, 12),
          status: 'completed',
          bedId: 'Bed 8',
          elapsedSeconds: 14400,
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        child: ProviderScope(
          overrides: [
            patientPortalControllerProvider.overrideWith(
              (ref) => _TestPatientPortalController(ref, portal),
            ),
          ],
          child: const MaterialApp(home: MainShellView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mon, Wed, Fri · Morning'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Jordan Patient'), findsOneWidget);
    expect(find.text('PT-2026-0001'), findsOneWidget);
    expect(find.text('555-0100'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bed 8'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bed 8'), findsOneWidget);
    expect(find.textContaining('Dry weight'), findsNothing);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('09/20/2026'), findsOneWidget);
    expect(find.text('Start 08:00  ·  End 12:00'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  test(
    'patient portal reloads profile when authenticated user changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final auth = _TestAuthController();
      final service = _SequencedPatientPortalService(ApiService(preferences), [
        PatientPortalSnapshot(
          profile: _portalProfile('patient-a', 'Patient A'),
          schedules: const [],
        ),
        PatientPortalSnapshot(
          profile: _portalProfile('patient-b', 'Patient B'),
          schedules: const [],
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith((ref) => auth),
          patientPortalServiceProvider.overrideWithValue(service),
          sessionTimerControllerProvider.overrideWith(
            (ref) => _NoopPatientSessionTimerController(ref),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        patientPortalControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      auth.setPatient('user-a');
      await _waitForPatient(container, 'Patient A');
      expect(
        container.read(patientPortalControllerProvider).profile?.id,
        'patient-a',
      );

      auth.setPatient('user-b');
      await _waitForPatient(container, 'Patient B');
      expect(
        container.read(patientPortalControllerProvider).profile?.id,
        'patient-b',
      );
      expect(service.fetchCount, 2);
    },
  );

  test('router provides named route transitions and fallback', () {
    final signInRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRouter.signIn),
    );
    final fallbackRoute = AppRouter.onGenerateRoute(
      const RouteSettings(name: '/missing'),
    );

    expect(signInRoute, isA<PageRoute<dynamic>>());
    expect(fallbackRoute, isA<PageRoute<dynamic>>());
  });
}

class _TestPatientPortalController extends PatientPortalController {
  _TestPatientPortalController(Ref ref, PatientPortalState initialState)
    : super(
        ref,
        authenticatedUserId: 'test-user',
        isAuthenticatedPatient: true,
      ) {
    state = initialState;
  }

  @override
  Future<void> load() async {}
}

class _TestAuthController extends AuthController {
  _TestAuthController() : super();

  void setPatient(String userId) {
    state = AuthState(
      user: {'id': userId, 'role': 'patient'},
      selectedRole: UserRole.patient,
    );
  }
}

class _SequencedPatientPortalService extends PatientPortalService {
  _SequencedPatientPortalService(super.api, this._snapshots);

  final List<PatientPortalSnapshot> _snapshots;
  int fetchCount = 0;

  @override
  Future<PatientPortalSnapshot> fetchPortal() async => _snapshots[fetchCount++];

  @override
  Future<List<PatientSessionHistoryItem>> fetchSessionHistory(
    String patientId,
  ) async => const [];
}

class _NoopPatientSessionTimerController extends SessionTimerController {
  _NoopPatientSessionTimerController(Ref ref) : super(ref);

  @override
  Future<void> hydratePatientSession({
    required String patientId,
    required String patientMedicalId,
    String? assignedBedId,
  }) async {}
}

PatientProfileModel _portalProfile(String id, String name) =>
    PatientProfileModel(
      id: id,
      name: name,
      medicalId: 'PT-$id',
      phone: '555-0100',
      bloodGroup: 'O+',
      vascularAccessType: 'Fistula',
      dryWeight: 70,
      baselineSystolic: 120,
      baselineDiastolic: 80,
      emergencyContact: 'Family',
      nephrologistName: 'Care team',
    );

Future<void> _waitForPatient(
  ProviderContainer container,
  String expectedName,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(patientPortalControllerProvider).profile?.name ==
        expectedName) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Patient portal did not load $expectedName.');
}
