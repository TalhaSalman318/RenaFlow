import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/appointment_timer_controller.dart';
import '../controllers/session_timer_controller.dart';
import '../models/live_session_model.dart';
import '../models/patient_profile_model.dart';
import '../services/notification_service.dart';
import 'session_history_view.dart';

class PatientDashboardView extends ConsumerStatefulWidget {
  const PatientDashboardView({super.key, required this.profile});

  final PatientProfileModel profile;

  @override
  ConsumerState<PatientDashboardView> createState() =>
      _PatientDashboardViewState();
}

class _PatientDashboardViewState extends ConsumerState<PatientDashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressRotation;

  @override
  void initState() {
    super.initState();
    _progressRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    Future<void>.microtask(() {
      if (!mounted) return;
      final appointments = ref.read(appointmentControllerProvider).appointments;
      if (appointments.isNotEmpty) {
        final appointment = appointments.first;
        ref
            .read(notificationServiceProvider.notifier)
            .schedulePreSessionAlert(
              patientName: widget.profile.medicalId,
              sessionStart: appointment.startTime,
              bedId: appointment.bedId ?? 'assigned bed',
            );
      }
    });
  }

  @override
  void dispose() {
    _progressRotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dashboardControllerProvider);
    final notification = ref.watch(notificationServiceProvider);
    final timers = ref.watch(sessionTimerControllerProvider);
    final liveTimer = timers.values.isEmpty ? null : timers.values.first;
    final appointmentState = ref.watch(appointmentTimerControllerProvider);
    final upcomingSession = appointmentState.forPatient(widget.profile.name);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (notification.isVisible) ...[
                SizedBox(height: 14.h),
                _buildReminder(notification.message!),
              ],
              SizedBox(height: 14.h),
              _buildPatientIdCard(),
              SizedBox(height: 10.h),
              _buildPatientDetailsCard(),
              SizedBox(height: 14.h),
              _buildScheduleCard(liveTimer, upcomingSession),
              SizedBox(height: 22.h),
              _buildSessionCard(session),
              SizedBox(height: 22.h),
              Text(
                'Quick actions',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10.h),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                'Your care dashboard',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w800,
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

  Widget _buildPatientIdCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17.r),
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
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  widget.profile.medicalId,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.profile.name,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            widget.profile.age == 0
                ? widget.profile.gender
                : '${widget.profile.age} years · ${widget.profile.gender}',
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _detailTag('Dry ${widget.profile.dryWeight} kg'),
              _detailTag(widget.profile.vascularAccessType),
              _detailTag(
                'BP ${widget.profile.baselineSystolic}/${widget.profile.baselineDiastolic}',
              ),
              _detailTag(widget.profile.assignedBedId ?? 'Bed pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.softPinkBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.secondaryRed,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReminder(String message) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: AppColors.white,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    BedSessionTimer? timer,
    AppointmentTimerSnapshot? appointment,
  ) {
    final isPaused = timer?.status == SessionTimerStatus.paused;
    final isRunning = timer?.status == SessionTimerStatus.running;
    final isCountdownVisible = appointment?.isWithin24Hours ?? false;
    final title = isRunning
        ? 'Time remaining: ${_formatTimer(timer!.remainingSeconds)}'
        : isPaused
        ? 'Session paused for clinical review'
        : isCountdownVisible
        ? 'Session starts in ${appointment!.countdown}'
        : 'Next session schedule';
    final subtitle = isRunning || isPaused
        ? '${timer!.bedId} · ${isPaused ? 'Nurse paused the session' : 'Live dialysis session'}'
        : appointment == null
        ? 'Your next recurring slot will appear here.'
        : '${appointment.appointment.bedId ?? 'Bed pending'} · ${_formatAppointmentDate(appointment.appointment.startTime)}';
    final cardColor = isPaused
        ? AppColors.secondaryRed
        : isCountdownVisible
        ? AppColors.primaryDark
        : AppColors.white;
    final foregroundColor = cardColor == AppColors.white
        ? AppColors.primaryDark
        : AppColors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: isCountdownVisible || isPaused
              ? AppColors.secondaryRed
              : AppColors.lightCoral,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRunning || isCountdownVisible
                ? Icons.timer_outlined
                : Icons.calendar_month_outlined,
            color: foregroundColor,
            size: 23.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: foregroundColor.withValues(
                      alpha: cardColor == AppColors.white ? 1 : 0.78,
                    ),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAppointmentDate(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} at $hour:$minute $period';
  }

  String _formatTimer(int seconds) {
    return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildSessionCard(LiveSessionModel session) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _progressRotation,
            builder: (context, _) => _SessionProgress(
              progress: session.completionPercentage,
              rotation: _progressRotation.value,
            ),
          ),
          SizedBox(width: 18.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dialysis session',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${_formatDuration(session.elapsedTime)} of ${_formatDuration(session.totalDuration)}',
                  style: TextStyle(
                    color: AppColors.softPinkBg,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      color: AppColors.lightCoral,
                      size: 17.r,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '${session.bloodFlowRate} mL/min',
                      style: TextStyle(color: AppColors.white, fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionButton(
          icon: Icons.emergency_outlined,
          label: 'Emergency',
          onTap: () => _showActionMessage('Emergency help is ready.'),
        ),
        _QuickActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Nephrologist',
          onTap: () => _showActionMessage('Opening nephrologist chat.'),
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_outlined,
          label: 'Session logs',
          onTap: _openSessionHistory,
        ),
      ],
    );
  }

  void _showActionMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSessionHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SessionHistoryView()));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
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

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 130),
        child: SizedBox(
          width: 100.w,
          child: Column(
            children: [
              Container(
                height: 48.r,
                width: 48.r,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  widget.icon,
                  color: AppColors.primaryDark,
                  size: 22.r,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: AppColors.secondaryRed,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
