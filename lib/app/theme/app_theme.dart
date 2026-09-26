import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

abstract final class AppSpacing {
  static const double xsmall = 8;
  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
}

abstract final class AppRadii {
  static const double card = 12;
  static const double panel = 16;
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryDark,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryDark,
          onPrimary: AppColors.white,
          secondary: AppColors.secondaryRed,
          onSecondary: AppColors.white,
          surface: AppColors.white,
          error: AppColors.primaryDark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme:
          const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
            displaySmall: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
            labelSmall: TextStyle(
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ).apply(
            bodyColor: AppColors.primaryDark,
            displayColor: AppColors.primaryDark,
          ),
      scaffoldBackgroundColor: AppColors.softPinkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.softPinkBg,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        actionsIconTheme: IconThemeData(size: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppColors.mediumPink),
        prefixIconColor: AppColors.secondaryRed,
        suffixIconColor: AppColors.secondaryRed,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.lightCoral),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.secondaryRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.secondaryRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ).copyWith(
              backgroundBuilder: (context, states, child) {
                final isDisabled = states.contains(WidgetState.disabled);
                final isPressed = states.contains(WidgetState.pressed);

                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryDark.withValues(
                          alpha: isDisabled ? 0.45 : 1,
                        ),
                        AppColors.secondaryRed.withValues(
                          alpha: isDisabled
                              ? 0.45
                              : isPressed
                              ? 0.9
                              : 1,
                        ),
                      ],
                    ),
                  ),
                  child: child,
                );
              },
            ),
      ),
    );
  }
}
