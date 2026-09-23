import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../controllers/queue_matching_controller.dart';
import '../controllers/appointment_timer_controller.dart';
import '../controllers/sanitization_controller.dart';
import '../models/queue_patient_model.dart';
import '../models/sanitization_task_model.dart';

class QueueSanitizationView extends StatelessWidget {
  const QueueSanitizationView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RenalFlow operations',
                            style: TextStyle(
                              color: AppColors.mediumPink,
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Patient flow',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 28.sp,
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
                      child: const Icon(
                        Icons.hub_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.secondaryRed,
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: const [
                      Tab(text: 'Queue matching'),
                      Tab(text: 'Sanitization'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              const Expanded(
                child: TabBarView(children: [_QueueTab(), _SanitizationTab()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueTab extends ConsumerWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(queueMatchingControllerProvider);
    final appointmentTimers = ref.watch(appointmentTimerControllerProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 26.h),
      children: [
        _QueueSummary(count: state.waitingPatients.length),
        if (appointmentTimers.preparingSessions.isNotEmpty) ...[
          SizedBox(height: 12.h),
          ...appointmentTimers.preparingSessions.map(
            (snapshot) => _PreparingQueueAlert(snapshot: snapshot),
          ),
        ],
        SizedBox(height: 16.h),
        if (state.waitingPatients.isEmpty)
          _EmptyQueue()
        else
          ...state.sortedPatients.asMap().entries.map(
            (entry) => _AnimatedQueueCard(
              key: ValueKey(entry.value.patientId),
              patient: entry.value,
              index: entry.key,
              isRecentlyAssigned:
                  state.recentlyAssignedPatientId == entry.value.patientId,
              onMatch: () => _openRecommendations(context, ref, entry.value),
            ),
          ),
        if (state.isMatching)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: const LinearProgressIndicator(
              color: AppColors.primaryDark,
              backgroundColor: AppColors.lightCoral,
            ),
          ),
        if (state.recentlyAssignedPatientId != null)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Text(
              'Bed assignment confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openRecommendations(
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

class _PreparingQueueAlert extends StatelessWidget {
  const _PreparingQueueAlert({required this.snapshot});

  final AppointmentTimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bedId = snapshot.appointment.bedId ?? 'Bed pending';
    final overlap = snapshot.hasOverlap;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: overlap ? AppColors.secondaryRed : AppColors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: overlap ? AppColors.secondaryRed : AppColors.lightCoral,
        ),
      ),
      child: Row(
        children: [
          Icon(
            overlap
                ? Icons.warning_amber_rounded
                : Icons.local_shipping_outlined,
            color: overlap ? AppColors.white : AppColors.primaryDark,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              overlap
                  ? '$bedId currently active - ${snapshot.currentBed!.remainingMinutes ?? 30}m remaining for current patient ${snapshot.currentBed!.patientName}'
                  : '$bedId · Preparing Next Patient (In 30m)',
              style: TextStyle(
                color: overlap ? AppColors.white : AppColors.primaryDark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            snapshot.countdown,
            style: TextStyle(
              color: overlap ? AppColors.softPinkBg : AppColors.secondaryRed,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(19.r),
      ),
      child: Row(
        children: [
          Container(
            height: 42.r,
            width: 42.r,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: AppColors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count patients waiting',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Priority matching is ready',
                  style: TextStyle(
                    color: AppColors.softPinkBg,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome, color: AppColors.lightCoral),
        ],
      ),
    );
  }
}

class _AnimatedQueueCard extends StatefulWidget {
  const _AnimatedQueueCard({
    super.key,
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

class _SanitizationTab extends ConsumerWidget {
  const _SanitizationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(sanitizationControllerProvider);
    final controller = ref.read(sanitizationControllerProvider.notifier);
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 26.h),
      children: [
        Text(
          'Auto-sanitization turnaround',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 19.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          'Complete each protocol before a bed returns to ready.',
          style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
        ),
        SizedBox(height: 16.h),
        ...tasks.asMap().entries.map(
          (entry) => _SanitizationCard(
            task: entry.value,
            index: entry.key,
            onToggle: controller.toggleStep,
          ),
        ),
      ],
    );
  }
}

class _SanitizationCard extends StatefulWidget {
  const _SanitizationCard({
    required this.task,
    required this.index,
    required this.onToggle,
  });

  final SanitizationTaskModel task;
  final int index;
  final void Function(String bedId, int stepIndex) onToggle;

  @override
  State<_SanitizationCard> createState() => _SanitizationCardState();
}

class _SanitizationCardState extends State<_SanitizationCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final minutes = (task.remainingTimeSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (task.remainingTimeSeconds % 60).toString().padLeft(2, '0');
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 390),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(19.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CountdownRing(
                    progress: task.remainingTimeSeconds / 300,
                    label: '$minutes:$seconds',
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.bedId,
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          task.currentStepIndex == task.totalSteps
                              ? 'Ready after timer'
                              : 'Sanitizing in progress',
                          style: TextStyle(
                            color: AppColors.mediumPink,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${task.currentStepIndex}/${task.totalSteps}',
                    style: TextStyle(
                      color: AppColors.secondaryRed,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: task.progress),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 7.h,
                    backgroundColor: AppColors.softPinkBg,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              _ChecklistRow(
                label: 'UV sterilization',
                checked: task.isUvSterilized,
                onTap: () => widget.onToggle(task.bedId, 0),
              ),
              _ChecklistRow(
                label: 'Filter flush',
                checked: task.isFilterFlushed,
                onTap: () => widget.onToggle(task.bedId, 1),
              ),
              _ChecklistRow(
                label: 'Line replacement',
                checked: task.isLineChanged,
                onTap: () => widget.onToggle(task.bedId, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 22.r,
              width: 22.r,
              decoration: BoxDecoration(
                color: checked ? AppColors.primaryDark : Colors.transparent,
                borderRadius: BorderRadius.circular(7.r),
                border: Border.all(
                  color: checked ? AppColors.primaryDark : AppColors.lightCoral,
                  width: 1.5,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: checked
                    ? const Icon(
                        Icons.check,
                        key: ValueKey('checked'),
                        color: AppColors.white,
                        size: 15,
                      )
                    : const SizedBox(key: ValueKey('unchecked')),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                color: checked ? AppColors.primaryDark : AppColors.secondaryRed,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66.r,
      width: 66.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, _) => CustomPaint(
              size: Size.square(66.r),
              painter: _CountdownPainter(value),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  const _CountdownPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5.r;
    final track = Paint()
      ..color = AppColors.softPinkBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.r;
    final active = Paint()
      ..color = progress < 0.25 ? AppColors.secondaryRed : AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.r
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        children: [
          Icon(Icons.done_all, color: AppColors.lightCoral, size: 48.r),
          SizedBox(height: 12.h),
          Text(
            'Queue is clear',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Every waiting patient has a bed.',
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
          ),
        ],
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

String _priorityLabel(PatientPriority priority) {
  return switch (priority) {
    PatientPriority.high => 'HIGH',
    PatientPriority.medium => 'MEDIUM',
    PatientPriority.low => 'LOW',
  };
}
