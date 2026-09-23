import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/routes/app_router.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingMedicalProfileView extends ConsumerStatefulWidget {
  const OnboardingMedicalProfileView({super.key});

  @override
  ConsumerState<OnboardingMedicalProfileView> createState() =>
      _OnboardingMedicalProfileViewState();
}

class _OnboardingMedicalProfileViewState
    extends ConsumerState<OnboardingMedicalProfileView> {
  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(onboardingControllerProvider.notifier);
    final currentStep = ref.read(onboardingControllerProvider).currentStep;
    if (currentStep == 0) {
      controller.nextStep();
      return;
    }

    final profile = await controller.complete();
    if (profile != null && mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRouter.mainShell, arguments: profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (state.currentStep > 0)
                    IconButton(
                      onPressed: controller.previousStep,
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.primaryDark,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 40.r),
                    ),
                  if (state.currentStep == 0) SizedBox(width: 40.r),
                  Expanded(
                    child: Text(
                      'Set up your care profile',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 23.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${state.currentStep + 1} of 2',
                    style: TextStyle(
                      color: AppColors.secondaryRed,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              _buildProgressBar(state.progress),
              SizedBox(height: 28.h),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                reverseDuration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) {
                  final offsetAnimation =
                      Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: state.currentStep == 0
                    ? _buildMedicalDetails(state)
                    : _buildEmergencyDetails(state),
              ),
              SizedBox(height: 28.h),
              _buildActionButton(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8.h,
              backgroundColor: AppColors.lightCoral.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryDark),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            progress == 1 ? 'Almost there' : 'Your medical details come first',
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalDetails(OnboardingState state) {
    return _AnimatedFormCard(
      key: const ValueKey('medical-details'),
      title: 'Medical details',
      subtitle: 'Help us personalize your dialysis care plan.',
      children: [
        _fieldLabel('Vascular access'),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _accessCard('AV Fistula', Icons.hub_outlined, state),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _accessCard('Catheter', Icons.cable_outlined, state),
            ),
          ],
        ),
        if (state.errors['vascularAccessType'] != null)
          _errorText(state.errors['vascularAccessType']!),
        SizedBox(height: 22.h),
        _fieldLabel('Dry weight'),
        SizedBox(height: 8.h),
        _inputField(
          hint: 'e.g. 68.5',
          suffix: 'kg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: state.errors['dryWeight'],
          onChanged: ref
              .read(onboardingControllerProvider.notifier)
              .setDryWeight,
        ),
        SizedBox(height: 22.h),
        _fieldLabel('Baseline blood pressure'),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _inputField(
                hint: 'Systolic',
                suffix: 'mmHg',
                keyboardType: TextInputType.number,
                errorText: state.errors['baselineSystolic'],
                onChanged: ref
                    .read(onboardingControllerProvider.notifier)
                    .setBaselineSystolic,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                '/',
                style: TextStyle(fontSize: 22.sp, color: AppColors.mediumPink),
              ),
            ),
            Expanded(
              child: _inputField(
                hint: 'Diastolic',
                suffix: 'mmHg',
                keyboardType: TextInputType.number,
                errorText: state.errors['baselineDiastolic'],
                onChanged: ref
                    .read(onboardingControllerProvider.notifier)
                    .setBaselineDiastolic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyDetails(OnboardingState state) {
    return _AnimatedFormCard(
      key: const ValueKey('emergency-details'),
      title: 'Emergency contacts',
      subtitle: 'Keep someone close in the loop when it matters.',
      children: [
        _fieldLabel('Emergency contact'),
        SizedBox(height: 8.h),
        _inputField(
          hint: 'Name and phone number',
          prefixIcon: Icons.contact_phone_outlined,
          keyboardType: TextInputType.phone,
          errorText: state.errors['emergencyContact'],
          onChanged: ref
              .read(onboardingControllerProvider.notifier)
              .setEmergencyContact,
        ),
        SizedBox(height: 22.h),
        _fieldLabel('Nephrologist name'),
        SizedBox(height: 8.h),
        _inputField(
          hint: 'Dr. Name',
          prefixIcon: Icons.medical_information_outlined,
          errorText: state.errors['nephrologistName'],
          onChanged: ref
              .read(onboardingControllerProvider.notifier)
              .setNephrologistName,
        ),
        SizedBox(height: 18.h),
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.softPinkBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.primaryDark,
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Your emergency details are only shared when you need support.',
                  style: TextStyle(
                    color: AppColors.secondaryRed,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accessCard(String label, IconData icon, OnboardingState state) {
    final selected = state.vascularAccessType == label;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryDark : AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: selected ? AppColors.primaryDark : AppColors.lightCoral,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.18),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () => ref
            .read(onboardingControllerProvider.notifier)
            .setVascularAccess(label),
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.white : AppColors.primaryDark,
              size: 28.r,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.primaryDark,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    String? suffix,
    String? errorText,
    IconData? prefixIcon,
  }) {
    return TextField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.primaryDark, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        errorText: errorText,
        errorMaxLines: 2,
      ),
    );
  }

  Widget _buildActionButton(OnboardingState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _continue,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: state.isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  height: 22.r,
                  width: 22.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  state.currentStep == 0 ? 'Continue' : 'Complete setup',
                  key: const ValueKey('label'),
                  style: TextStyle(fontSize: 15.sp),
                ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.primaryDark,
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _errorText(String message) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Text(
        message,
        style: TextStyle(color: AppColors.secondaryRed, fontSize: 12.sp),
      ),
    );
  }
}

class _AnimatedFormCard extends StatefulWidget {
  const _AnimatedFormCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  State<_AnimatedFormCard> createState() => _AnimatedFormCardState();
}

class _AnimatedFormCardState extends State<_AnimatedFormCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 360),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _visible ? 0 : 8.h, 0),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.07),
              blurRadius: 18.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              widget.subtitle,
              style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
            ),
            SizedBox(height: 24.h),
            ...widget.children,
          ],
        ),
      ),
    );
  }
}
