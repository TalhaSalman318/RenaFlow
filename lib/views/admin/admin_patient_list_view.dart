import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/constants/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../controllers/admin_patient_controller.dart';
import '../../models/patient_model.dart';
import '../../widgets/app_logo_header.dart';
import 'admin_add_patient_view.dart';
import 'schedule_session_dialog.dart';

class AdminPatientListView extends ConsumerStatefulWidget {
  const AdminPatientListView({super.key});

  @override
  ConsumerState<AdminPatientListView> createState() =>
      _AdminPatientListViewState();
}

class _AdminPatientListViewState extends ConsumerState<AdminPatientListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPatientControllerProvider);
    final controller = ref.read(adminPatientControllerProvider.notifier);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AdminAddPatientView()),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add patient'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.medium.w,
                AppSpacing.medium.h,
                AppSpacing.medium.w,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(context, state, controller),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.medium.w,
                AppSpacing.medium.h,
                AppSpacing.medium.w,
                100.h,
              ),
              sliver: state.filteredPatients.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(context))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnimatedPatientCard(
                          patient: state.filteredPatients[index],
                          index: index,
                          onTap: () =>
                              _showActions(state.filteredPatients[index]),
                        ),
                        childCount: state.filteredPatients.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminPatientState state,
    AdminPatientController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Patient management',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            Text(
              '${state.patients.length} records',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.mediumPink),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Text(
          'Profiles, clinical parameters, and bed assignments.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumPink),
        ),
        SizedBox(height: 18.h),
        TextField(
          controller: _searchController,
          onChanged: controller.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search name or Medical ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      controller.setSearchQuery('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 55.h),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            color: AppColors.lightCoral,
            size: 44.r,
          ),
          SizedBox(height: 12.h),
          Text(
            'No patients found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primaryDark),
          ),
          SizedBox(height: 5.h),
          Text(
            'Try another name or Medical ID.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mediumPink),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(PatientModel patient) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientActionsSheet(
        patient: patient,
        onSchedule: () => _openScheduleDialog(patient),
      ),
    );
  }

  Future<void> _openScheduleDialog(PatientModel patient) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.softPinkBg,
      builder: (_) => ScheduleSessionDialog(patient: patient),
    );
  }
}

class _AnimatedPatientCard extends StatefulWidget {
  const _AnimatedPatientCard({
    required this.patient,
    required this.index,
    required this.onTap,
  });

  final PatientModel patient;
  final int index;
  final VoidCallback onTap;

  @override
  State<_AnimatedPatientCard> createState() => _AnimatedPatientCardState();
}

class _AnimatedPatientCardState extends State<_AnimatedPatientCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, .08),
        duration: const Duration(milliseconds: 380),
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xsmall.h),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.panel.r),
            child: _PatientCard(patient: widget.patient),
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.panel.r),
        border: Border.all(color: AppColors.lightCoral.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            height: 45.r,
            width: 45.r,
            decoration: BoxDecoration(
              color: AppColors.softPinkBg,
              borderRadius: BorderRadius.circular(AppRadii.card.r),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: AppSpacing.xsmall.w,
                  runSpacing: 4.h,
                  children: [
                    _tag(patient.medicalId, AppColors.secondaryRed),
                    _tag(patient.vascularAccess, AppColors.mediumPink),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  patient.assignedBedId ?? 'No bed assigned',
                  style: TextStyle(
                    color: patient.assignedBedId == null
                        ? AppColors.mediumPink
                        : AppColors.primaryDark,
                    fontSize: 11.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
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

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PatientActionsSheet extends StatelessWidget {
  const _PatientActionsSheet({required this.patient, required this.onSchedule});

  final PatientModel patient;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium.w,
        12.h,
        AppSpacing.medium.w,
        25.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.softPinkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38.w,
              height: 4.h,
              color: AppColors.lightCoral,
            ),
          ),
          SizedBox(height: 18.h),
          const AppLogoHeader(compact: true),
          SizedBox(height: 10.h),
          Text(
            patient.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark),
          ),
          Text(
            '${patient.medicalId} · ${patient.age} years · ${patient.gender}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mediumPink),
          ),
          SizedBox(height: 16.h),
          _button(
            Icons.medical_information_outlined,
            'View medical profile',
            () => _profileDialog(context),
          ),
          SizedBox(height: 8.h),
          _button(
            Icons.calendar_month_outlined,
            'Schedule dialysis session',
            onSchedule,
          ),
        ],
      ),
    );
  }

  Widget _button(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.lightCoral),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  void _profileDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const AppLogoHeader(compact: true),
        content: Text(
          'Dry weight: ${patient.dryWeight} kg\nVascular access: ${patient.vascularAccess}\nBaseline BP: ${patient.baselineBp}\nNephrologist: ${patient.nephrologist}\nEmergency: ${patient.emergencyContact}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
