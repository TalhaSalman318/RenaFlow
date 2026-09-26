import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../views/main_shell_view.dart';
import '../../views/onboarding_medical_profile_view.dart';
import '../../views/signin_view.dart';
import '../../views/splash_view.dart';
import '../../widgets/app_logo_header.dart';

class AppLaunchArguments {
  const AppLaunchArguments({required this.role});

  final UserRole role;
}

abstract final class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const splash = '/';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';
  static const mainShell = '/app';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      splash => const SplashView(),
      signIn => const SignInView(),
      onboarding => const OnboardingMedicalProfileView(),
      mainShell => _buildMainShell(settings.arguments),
      _ => const AppRouteFallback(),
    };
    return _fadeSlide(page, settings);
  }

  static Widget _buildMainShell(Object? arguments) {
    if (arguments is AppLaunchArguments) {
      return MainShellView(
        initialMode: arguments.role == UserRole.admin
            ? AppMode.adminNurse
            : AppMode.patient,
      );
    }
    return MainShellView(
      initialMode: arguments is UserRole && arguments == UserRole.admin
          ? AppMode.adminNurse
          : AppMode.patient,
    );
  }

  static PageRouteBuilder<void> _fadeSlide(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 420),
    );
  }
}

class AppRouteFallback extends StatelessWidget {
  const AppRouteFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogoHeader(compact: true),
              const SizedBox(height: 20),
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('This screen is unavailable right now.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRouter.splash, (_) => false),
                child: const Text('Return to start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
