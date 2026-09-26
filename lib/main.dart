import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const RenalFlowApp(),
    ),
  );
}

class RenalFlowApp extends ConsumerWidget {
  const RenalFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(authSessionExpiredProvider, (previous, expired) {
      if (expired != true) return;
      unawaited(ref.read(authControllerProvider.notifier).logout());
      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (_) => false,
      );
    });
    ref.watch(socketServiceProvider);
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        title: 'RenalFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
      child: const SizedBox.shrink(),
    );
  }
}
