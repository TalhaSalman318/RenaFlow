import 'dart:async';

import 'package:flutter/material.dart';

import '../app/constants/app_colors.dart';
import '../app/routes/app_router.dart';
import '../widgets/app_logo_header.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _navigationTimer = Timer(const Duration(seconds: 3), _openSignIn);
  }

  void _openSignIn() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.signIn);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPinkBg,
      body: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeInOut,
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [const AppLogoHeader(showCard: false)],
            ),
          ),
        ),
      ),
    );
  }
}
