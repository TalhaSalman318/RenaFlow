import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/constants/app_colors.dart';
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
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(state, controller),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 100.h),
              sliver: state.filteredPatients.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
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
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${state.patients.length} records',
              style: TextStyle(color: AppColors.mediumPink, fontSize: 11.sp),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Text(
          'Profiles, clinical parameters, and bed assignments.',
          style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
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

  Widget _buildEmptyState() {
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
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Try another name or Medical ID.',
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
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
          padding: EdgeInsets.only(bottom: 11.h),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18.r),
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
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightCoral.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            height: 45.r,
            width: 45.r,
            decoration: BoxDecoration(
              color: AppColors.softPinkBg,
              borderRadius: BorderRadius.circular(13.r),
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
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    _tag(patient.medicalId, AppColors.secondaryRed),
                    SizedBox(width: 5.w),
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
                    fontWeight: FontWeight.w700,
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
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
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
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 25.h),
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
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${patient.medicalId} · ${patient.age} years · ${patient.gender}',
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
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
