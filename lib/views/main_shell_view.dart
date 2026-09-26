import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/routes/app_router.dart';
import '../app/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/patient_portal_controller.dart';
import '../widgets/app_logo_header.dart';
import 'admin/admin_patient_list_view.dart';
import 'bed_matrix_view.dart';
import 'patient_dashboard_view.dart';
import 'queue_sanitization_view.dart';
import 'session_history_view.dart';

class MainShellView extends ConsumerStatefulWidget {
  const MainShellView({super.key, this.initialMode});

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

  @override
  Widget build(BuildContext context) {
    final navigation = ref.watch(navigationControllerProvider);
    final controller = ref.read(navigationControllerProvider.notifier);
    final activeMode = widget.initialMode ?? navigation.mode;
    final isPatient = activeMode == AppMode.patient;
    final patientPortal = isPatient
        ? ref.watch(patientPortalControllerProvider)
        : null;
    final tabs = isPatient
        ? <Widget>[
            PatientDashboardView(portal: patientPortal!),
            const PatientPortalHistoryView(),
            const _ProfileView(),
          ]
        : <Widget>[
            const BedMatrixView(),
            const QueueSanitizationView(),
            const AdminPatientListView(),
          ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppLogoHeader(compact: true, showCard: false),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRouter.signIn, (_) => false);
            },
            icon: const Icon(Icons.logout),
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
          ];
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppSpacing.medium.w,
          0,
          AppSpacing.medium.w,
          10.h,
        ),
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppRadii.panel.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.2),
              blurRadius: 2.r,
              offset: Offset(0, 1.h),
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
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.white),
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

class _ProfileView extends ConsumerWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portal = ref.watch(patientPortalControllerProvider);
    final profile = portal.profile;
    return ListView(
      padding: EdgeInsets.all(AppSpacing.medium.r),
      children: [
        if (profile == null && portal.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (profile == null)
          Text(portal.error ?? 'Patient profile is unavailable.')
        else ...[
          SizedBox(height: 8.h),
          Text(
            'Your profile',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 26.sp,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          SizedBox(height: 20.h),
          _profileCard(Icons.person_outline, 'Name', profile.name),
          _profileCard(Icons.badge_outlined, 'Medical ID', profile.medicalId),
          _profileCard(Icons.phone_outlined, 'Phone', profile.phone),
          _profileCard(
            Icons.bloodtype_outlined,
            'Blood group',
            profile.bloodGroup,
          ),
          _profileCard(
            Icons.bed_outlined,
            'Assigned bed',
            profile.assignedBedId ?? 'Unassigned',
          ),
        ],
      ],
    );
  }

  Widget _profileCard(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xsmall.h),
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.panel.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20.r),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
