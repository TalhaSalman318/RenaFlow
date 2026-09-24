import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rena_flow/app/routes/app_router.dart';
import 'package:rena_flow/controllers/navigation_controller.dart';
import 'package:rena_flow/main.dart';
import 'package:rena_flow/services/api_service.dart';
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
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(child: const MaterialApp(home: MainShellView())),
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });

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
