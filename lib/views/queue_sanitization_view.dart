import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../controllers/admin_patient_controller.dart';
import '../controllers/queue_matching_controller.dart';
import '../models/patient_model.dart';
import '../models/queue_patient_model.dart';
import 'patient_detail_management_screen.dart';

class QueueSanitizationView extends StatelessWidget {
  const QueueSanitizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1120.w),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.medium.w,
                    AppSpacing.medium.h,
                    AppSpacing.medium.w,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RenalFlow operations',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.mediumPink),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Patient flow',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 44.r,
                        width: 44.r,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: const Icon(
                          Icons.hub_outlined,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.small.h),
            const Expanded(child: _QueueTab()),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends ConsumerStatefulWidget {
  const _QueueTab();

  @override
  ConsumerState<_QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<_QueueTab> {
  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(adminPatientControllerProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 960.w),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.medium.w,
            AppSpacing.small.h,
            AppSpacing.medium.w,
            AppSpacing.large.h,
          ),
          itemCount: patientState.filteredPatients.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.small.h),
                child: TextField(
                  onChanged: ref
                      .read(adminPatientControllerProvider.notifier)
                      .setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search patients by name or Medical ID',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              );
            }
            final patient = patientState.filteredPatients[index - 1];
            return _FlowPatientCard(
              patient: patient,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PatientDetailManagementScreen(patient: patient),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> openRecommendations(
    BuildContext context,
    WidgetRef ref,
    QueuePatientModel patient,
  ) async {
    final controller = ref.read(queueMatchingControllerProvider.notifier);
    final recommendations = await controller.matchBed(patient);
    if (!context.mounted || recommendations.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecommendationSheet(
        patient: patient,
        recommendations: recommendations,
        onAssign: (bedId) {
          controller.assignBed(patient, bedId);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _FlowPatientCard extends StatelessWidget {
  const _FlowPatientCard({required this.patient, required this.onTap});

  final PatientModel patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xsmall.h),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.primaryDark,
                  size: 22.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profileText(patient.fullName, fallback: 'Unknown'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.primaryDark),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${_profileText(patient.medicalId, fallback: 'N/A')} · ${_profileText(patient.assignedBedId, fallback: 'Unassigned')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mediumPink,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mediumPink,
                  size: 24.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedQueueCard extends StatefulWidget {
  const _AnimatedQueueCard({
    required this.patient,
    required this.index,
    required this.isRecentlyAssigned,
    required this.onMatch,
  });

  final QueuePatientModel patient;
  final int index;
  final bool isRecentlyAssigned;
  final VoidCallback onMatch;

  @override
  State<_AnimatedQueueCard> createState() => _AnimatedQueueCardState();
}

class _AnimatedQueueCardState extends State<_AnimatedQueueCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 55 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: EdgeInsets.only(bottom: 11.h),
          child: _QueuePatientCard(
            patient: widget.patient,
            isRecentlyAssigned: widget.isRecentlyAssigned,
            onMatch: widget.onMatch,
          ),
        ),
      ),
    );
  }
}

class _QueuePatientCard extends StatelessWidget {
  const _QueuePatientCard({
    required this.patient,
    required this.isRecentlyAssigned,
    required this.onMatch,
  });

  final QueuePatientModel patient;
  final bool isRecentlyAssigned;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(patient.priorityScore);
    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: priorityColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            height: 43.r,
            width: 43.r,
            decoration: BoxDecoration(
              color: AppColors.softPinkBg,
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(Icons.person_outline, color: priorityColor, size: 23.r),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        patient.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 7.w),
                    _PriorityBadge(priority: patient.priorityScore),
                  ],
                ),
                SizedBox(height: 5.h),
                Text(
                  '${patient.patientId} · ${patient.vascularAccessType}',
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      color: AppColors.secondaryRed,
                      size: 15.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${patient.transportEtaMinutes} min away',
                      style: TextStyle(
                        color: AppColors.secondaryRed,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: isRecentlyAssigned
                ? Icon(
                    Icons.check_circle,
                    key: const ValueKey('assigned'),
                    color: AppColors.primaryDark,
                    size: 25.r,
                  )
                : OutlinedButton(
                    key: const ValueKey('match'),
                    onPressed: onMatch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Match',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final PatientPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        _priorityLabel(priority),
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecommendationSheet extends StatefulWidget {
  const _RecommendationSheet({
    required this.patient,
    required this.recommendations,
    required this.onAssign,
  });

  final QueuePatientModel patient;
  final List<BedRecommendation> recommendations;
  final ValueChanged<String> onAssign;

  @override
  State<_RecommendationSheet> createState() => _RecommendationSheetState();
}

class _RecommendationSheetState extends State<_RecommendationSheet> {
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
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.15),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: AppColors.softPinkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.lightCoral,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 19.h),
            Text(
              'Recommended beds',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Best matches for ${widget.patient.name}',
              style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            ...widget.recommendations.asMap().entries.map(
              (entry) => _RecommendationTile(
                recommendation: entry.value,
                index: entry.key,
                onTap: () => widget.onAssign(entry.value.bedId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatefulWidget {
  const _RecommendationTile({
    required this.recommendation,
    required this.index,
    required this.onTap,
  });

  final BedRecommendation recommendation;
  final int index;
  final VoidCallback onTap;

  @override
  State<_RecommendationTile> createState() => _RecommendationTileState();
}

class _RecommendationTileState extends State<_RecommendationTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bed_outlined,
                  color: AppColors.primaryDark,
                  size: 24.r,
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Text(
                    widget.recommendation.bedId,
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${widget.recommendation.matchScore}% Match',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 7.w),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.mediumPink,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _priorityColor(PatientPriority priority) {
  return switch (priority) {
    PatientPriority.high => AppColors.primaryDark,
    PatientPriority.medium => AppColors.secondaryRed,
    PatientPriority.low => AppColors.mediumPink,
  };
}

String _profileText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String _priorityLabel(PatientPriority priority) {
  return switch (priority) {
    PatientPriority.high => 'HIGH',
    PatientPriority.medium => 'MEDIUM',
    PatientPriority.low => 'LOW',
  };
}
