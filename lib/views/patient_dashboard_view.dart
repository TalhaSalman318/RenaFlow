import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../controllers/session_timer_controller.dart';
import '../models/patient_profile_model.dart';
import '../controllers/patient_portal_controller.dart';
import '../models/patient_portal_model.dart';

class PatientDashboardView extends ConsumerStatefulWidget {
  const PatientDashboardView({super.key, required this.portal});

  final PatientPortalState portal;

  @override
  ConsumerState<PatientDashboardView> createState() =>
      _PatientDashboardViewState();
}

class _PatientDashboardViewState extends ConsumerState<PatientDashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressRotation;

  PatientProfileModel get _profile => widget.portal.profile!;

  @override
  void initState() {
    super.initState();
    _progressRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _progressRotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.portal.profile == null) {
      return Scaffold(
        body: Center(
          child: widget.portal.isLoading
              ? const CircularProgressIndicator()
              : Text(widget.portal.error ?? 'Patient profile is unavailable.'),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 14.h),
              _buildPatientIdCard(context),
              SizedBox(height: 10.h),
              _buildPatientDetailsCard(context),
              SizedBox(height: 14.h),
              _buildScheduleCard(context, widget.portal.schedules),
              SizedBox(height: 22.h),
              Consumer(
                builder: (context, ref, _) {
                  final liveTimer = ref.watch(
                    sessionTimerControllerProvider.select((timers) {
                      for (final timer in timers.values) {
                        if ((timer.patientId == _profile.id ||
                                timer.patientMedicalId == _profile.medicalId) &&
                            timer.status != SessionTimerStatus.completed &&
                            timer.status != SessionTimerStatus.idle) {
                          return timer;
                        }
                      }
                      return null;
                    }),
                  );
                  return _buildSessionCard(liveTimer);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumPink),
              ),
              SizedBox(height: 4.h),
              Text(
                'Welcome, ${_profile.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryDark,
                ),
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
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientIdCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.panel.r),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: AppColors.primaryDark, size: 22.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient ID',
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 11.sp,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _profile.medicalId,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.panel.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal details',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _detailTag(context, 'Name: ${_profile.name}'),
              _detailTag(context, 'Phone: ${_profile.phone}'),
              _detailTag(context, 'Blood group: ${_profile.bloodGroup}'),
              _detailTag(
                context,
                'Assigned bed: ${_profile.assignedBedId ?? 'Unassigned'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTag(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.softPinkBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.secondaryRed),
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    List<PatientPortalSchedule> schedules,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.panel.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned dialysis days',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          if (schedules.isEmpty)
            Text(
              'No recurring dialysis schedule is assigned.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mediumPink),
            )
          else
            ...schedules.map(
              (schedule) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${schedule.assignedDays} · ${schedule.shift}',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '${schedule.startTime} - ${schedule.endTime} · ${schedule.bedId ?? _profile.assignedBedId ?? 'Bed pending'}',
                      style: TextStyle(
                        color: AppColors.mediumPink,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildSessionCard(BedSessionTimer? timer) {
    final progress = timer?.completionPercentage ?? 0;
    final paused = timer?.status == SessionTimerStatus.paused;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.medium.r),
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
          AnimatedBuilder(
            animation: _progressRotation,
            builder: (context, _) => _SessionProgress(
              progress: progress,
              rotation: _progressRotation.value,
            ),
          ),
          SizedBox(width: 18.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer == null
                      ? 'No active dialysis session'
                      : paused
                      ? 'Dialysis session'
                      : 'Dialysis in progress',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (paused)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, bottom: 2.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkBg,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Dialysis Paused',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                Text(
                  timer == null
                      ? 'Your live countdown will appear when treatment starts.'
                      : '${_formatTimer(timer.remainingSeconds)} remaining · ${_formatTimer(timer.elapsedSeconds)} elapsed',
                  style: TextStyle(
                    color: AppColors.softPinkBg,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  timer?.bedId ?? 'No bed session active',
                  style: TextStyle(color: AppColors.white, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionProgress extends StatelessWidget {
  const _SessionProgress({required this.progress, required this.rotation});

  final double progress;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final progressColor = Color.lerp(
      AppColors.lightCoral,
      AppColors.white,
      progress,
    )!;
    return SizedBox(
      height: 116.r,
      width: 116.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(116.r),
            painter: _ProgressPainter(
              progress: progress,
              color: progressColor,
              rotation: rotation,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress * 100),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, _) => Text(
                    '${value.round()}%',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 23.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'complete',
                  style: TextStyle(
                    color: AppColors.softPinkBg,
                    fontSize: 10.sp,
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

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({
    required this.progress,
    required this.color,
    required this.rotation,
  });

  final double progress;
  final Color color;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 7.r;
    final track = Paint()
      ..color = AppColors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.r
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.r
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + rotation * math.pi * 2,
      progress.clamp(0, 1) * math.pi * 2,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rotation != rotation ||
      oldDelegate.color != color;
}
