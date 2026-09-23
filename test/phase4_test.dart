import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rena_flow/controllers/session_history_controller.dart';
import 'package:rena_flow/views/session_history_view.dart';

void main() {
  test('filters session history by date, fluid removal, and search', () {
    final controller = SessionHistoryController();

    expect(controller.state.visibleSessions, hasLength(4));

    controller.setFilter(SessionHistoryFilter.last7Days);
    expect(controller.state.visibleSessions, hasLength(2));

    controller.setFilter(SessionHistoryFilter.highFluidRemoval);
    expect(controller.state.visibleSessions, hasLength(2));

    controller.setSearchQuery('Northside');
    expect(controller.state.visibleSessions, hasLength(0));

    controller.setFilter(SessionHistoryFilter.all);
    expect(controller.state.visibleSessions, hasLength(1));
  });

  testWidgets('renders session history search and filter controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(390, 844),
        child: ProviderScope(child: MaterialApp(home: SessionHistoryView())),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Session history'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('2.7 L removed'), findsOneWidget);
  });
}
