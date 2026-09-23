import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/routes/app_router.dart';
import '../controllers/auth_controller.dart';
import '../models/patient_profile_model.dart';
import '../widgets/app_logo_header.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});

  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final signedIn = await ref.read(authControllerProvider.notifier).signIn();
    if (signedIn && mounted) {
      final authState = ref.read(authControllerProvider);
      final role = authState.selectedRole;
      Navigator.of(context).pushReplacementNamed(
        AppRouter.mainShell,
        arguments: AppLaunchArguments(
          role: role,
          profile: role == UserRole.patient
              ? _patientProfileFor(authState.identifier)
              : null,
        ),
      );
    }
  }

  PatientProfileModel _patientProfileFor(String identifier) {
    final isLena = identifier.trim().toUpperCase() == 'RF-PT-1077';
    return isLena
        ? const PatientProfileModel(
            medicalId: 'RF-PT-1077',
            name: 'Lena Williams',
            age: 64,
            gender: 'Female',
            assignedBedId: null,
            vascularAccessType: 'AV Fistula',
            dryWeight: 68.5,
            baselineSystolic: 132,
            baselineDiastolic: 82,
            emergencyContact: 'Noah Williams · +1 555 0102',
            nephrologistName: 'Dr. Amina Rahman',
          )
        : PatientProfileModel(
            medicalId: identifier.trim().isEmpty
                ? 'RF-2026-8941'
                : identifier.trim(),
            name: 'RenalFlow Patient',
            age: 0,
            gender: 'Not provided',
            vascularAccessType: 'AV Fistula',
            dryWeight: 68.5,
            baselineSystolic: 128,
            baselineDiastolic: 78,
            emergencyContact: 'Care team · +1 555 0199',
            nephrologistName: 'Dr. Amina Rahman',
          );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 760.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AppLogoHeader()),
                SizedBox(height: 30.h),
                _buildRoleToggle(authState, authController),
                SizedBox(height: 34.h),
                Text(
                  'Welcome back',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sign in to continue your care journey',
                  style: TextStyle(
                    color: AppColors.secondaryRed,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 36.h),
                Text('Email or Medical ID', style: _labelStyle),
                SizedBox(height: 8.h),
                TextField(
                  focusNode: _identifierFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: authController.setIdentifier,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    hintText: 'Enter email or medical ID',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    errorText: authState.identifierError,
                  ),
                ),
                SizedBox(height: 20.h),
                Text('Password', style: _labelStyle),
                SizedBox(height: 8.h),
                TextField(
                  focusNode: _passwordFocusNode,
                  obscureText: !authState.isPasswordVisible,
                  textInputAction: TextInputAction.done,
                  onChanged: authController.setPassword,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: authState.passwordError,
                    suffixIcon: IconButton(
                      tooltip: authState.isPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: authController.togglePasswordVisibility,
                      icon: Icon(
                        authState.isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? SizedBox(
                            height: 22.r,
                            width: 22.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text('Sign In', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                SizedBox(height: 150.h),
                Center(
                  child: Text(
                    'Your health data stays private and secure.',
                    style: TextStyle(
                      color: AppColors.mediumPink,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => TextStyle(
    color: AppColors.primaryDark,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
  );

  Widget _buildRoleToggle(AuthState state, AuthController controller) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          _roleOption(
            label: 'Patient Portal',
            role: UserRole.patient,
            selected: state.selectedRole == UserRole.patient,
            onTap: () => controller.selectRole(UserRole.patient),
          ),
          _roleOption(
            label: 'Admin / Staff Portal',
            role: UserRole.admin,
            selected: state.selectedRole == UserRole.admin,
            onTap: () => controller.selectRole(UserRole.admin),
          ),
        ],
      ),
    );
  }

  Widget _roleOption({
    required String label,
    required UserRole role,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.secondaryRed,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
