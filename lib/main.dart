import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: RenalFlowApp()));
}

class RenalFlowApp extends StatelessWidget {
  const RenalFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
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
