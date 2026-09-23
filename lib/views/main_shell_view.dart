import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../controllers/navigation_controller.dart';
import '../models/patient_profile_model.dart';
import '../widgets/app_logo_header.dart';
import 'admin/admin_patient_list_view.dart';
import 'bed_matrix_view.dart';
import 'patient_dashboard_view.dart';
import 'queue_sanitization_view.dart';
import 'session_history_view.dart';

class MainShellView extends ConsumerStatefulWidget {
  const MainShellView({super.key, this.profile, this.initialMode});

  final PatientProfileModel? profile;
  final AppMode? initialMode;

  @override
  ConsumerState<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends ConsumerState<MainShellView> {
  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      Future<void>.microtask(() {
        if (mounted) {
          ref
              .read(navigationControllerProvider.notifier)
              .switchMode(widget.initialMode!);
        }
      });
    }
  }

  PatientProfileModel get _fallbackProfile => const PatientProfileModel(
    vascularAccessType: 'AV Fistula',
    dryWeight: 68.5,
    baselineSystolic: 128,
    baselineDiastolic: 78,
    emergencyContact: 'Care team · +1 555 0199',
    nephrologistName: 'Dr. Amina Rahman',
  );

  @override
  Widget build(BuildContext context) {
    final navigation = ref.watch(navigationControllerProvider);
    final controller = ref.read(navigationControllerProvider.notifier);
    final activeMode = widget.initialMode ?? navigation.mode;
    final isPatient = activeMode == AppMode.patient;
    final tabs = isPatient
        ? <Widget>[
            PatientDashboardView(profile: widget.profile ?? _fallbackProfile),
            const SessionHistoryView(),
            _ProfileView(profile: widget.profile ?? _fallbackProfile),
          ]
        : <Widget>[
            const BedMatrixView(),
            const QueueSanitizationView(),
            const AdminPatientListView(),
            const _OperationsLogsView(),
          ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppLogoHeader(compact: true, showCard: false),
        actions: [
          if (!isPatient)
            PopupMenuButton<AppMode>(
              tooltip: 'Switch role',
              icon: const Icon(Icons.swap_horiz),
              onSelected: controller.switchMode,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: AppMode.patient,
                  child: Text('Patient preview'),
                ),
                PopupMenuItem(
                  value: AppMode.adminNurse,
                  child: Text('Admin / Nurse view'),
                ),
              ],
            ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey('${navigation.mode}-${navigation.activeIndex}'),
          child: tabs[navigation.activeIndex],
        ),
      ),
      bottomNavigationBar: _AnimatedNavigationBar(
        index: navigation.activeIndex,
        isPatient: isPatient,
        onChanged: controller.setIndex,
      ),
    );
  }
}

class _AnimatedNavigationBar extends StatelessWidget {
  const _AnimatedNavigationBar({
    required this.index,
    required this.isPatient,
    required this.onChanged,
  });

  final int index;
  final bool isPatient;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = isPatient
        ? const [
            (Icons.monitor_heart_outlined, 'Live'),
            (Icons.history, 'History'),
            (Icons.person_outline, 'Profile'),
          ]
        : const [
            (Icons.grid_view_rounded, 'Beds'),
            (Icons.hub_outlined, 'Flow'),
            (Icons.people_alt_outlined, 'Patients'),
            (Icons.analytics_outlined, 'Analytics'),
          ];
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.2),
              blurRadius: 14.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(itemIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(vertical: 9.h),
                    decoration: BoxDecoration(
                      color: index == itemIndex
                          ? AppColors.white.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(17.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[itemIndex].$1,
                          color: AppColors.white,
                          size: 20.r,
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          items[itemIndex].$2,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final PatientProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        const AppLogoHeader(compact: true),
        SizedBox(height: 22.h),
        Text(
          'Your profile',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Your care details stay ready when you need them.',
          style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
        ),
        SizedBox(height: 24.h),
        _profileCard(
          Icons.medical_information_outlined,
          'Nephrologist',
          profile.nephrologistName,
        ),
        _profileCard(
          Icons.hub_outlined,
          'Vascular access',
          profile.vascularAccessType,
        ),
        _profileCard(
          Icons.monitor_weight_outlined,
          'Dry weight',
          '${profile.dryWeight} kg',
        ),
        _profileCard(
          Icons.favorite_border,
          'Baseline BP',
          '${profile.baselineSystolic}/${profile.baselineDiastolic} mmHg',
        ),
        _profileCard(
          Icons.contact_phone_outlined,
          'Emergency contact',
          profile.emergencyContact,
        ),
      ],
    );
  }

  Widget _profileCard(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 22.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Kept as a fallback reference for older shell state snapshots.
// ignore: unused_element
class _PatientManagementView extends StatelessWidget {
  const _PatientManagementView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        const AppLogoHeader(compact: true),
        SizedBox(height: 22.h),
        Text(
          'Patient management',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Manage profiles, care plans, and appointments.',
          style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
        ),
        SizedBox(height: 24.h),
        _managementAction(
          Icons.person_add_alt_1,
          'Add patient profile',
          'Create a new care record.',
        ),
        _managementAction(
          Icons.calendar_month_outlined,
          'Appointments',
          'Schedule and coordinate visits.',
        ),
        _managementAction(
          Icons.tune_outlined,
          'Medical parameters',
          'Review patient care settings.',
        ),
      ],
    );
  }

  Widget _managementAction(IconData icon, String title, String subtitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.lightCoral),
        ],
      ),
    );
  }
}

class _OperationsLogsView extends StatelessWidget {
  const _OperationsLogsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        Text(
          'Operations logs',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'A clear operational snapshot for the care team.',
          style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
        ),
        SizedBox(height: 24.h),
        _logCard(
          Icons.check_circle_outline,
          'All systems stable',
          'Live monitoring is active',
          AppColors.primaryDark,
        ),
        _logCard(
          Icons.cleaning_services_outlined,
          'Sanitization protocol',
          '3 beds in turnaround',
          AppColors.mediumPink,
        ),
        _logCard(
          Icons.people_outline,
          'Queue matching',
          '4 patients awaiting placement',
          AppColors.secondaryRed,
        ),
      ],
    );
  }

  Widget _logCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
