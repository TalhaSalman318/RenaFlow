import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../controllers/bed_matrix_controller.dart';
import '../controllers/appointment_timer_controller.dart';
import '../models/bed_model.dart';
import 'admin/admin_active_session_view.dart';

class BedMatrixView extends ConsumerWidget {
  const BedMatrixView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bedMatrixControllerProvider);
    final controller = ref.read(bedMatrixControllerProvider.notifier);
    final appointmentTimers = ref.watch(appointmentTimerControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: _buildHeader(state),
            ),
            SizedBox(height: 18.h),
            _buildFilters(state, controller),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Text(
                    'Bed matrix',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${state.visibleBeds.length} shown',
                    style: TextStyle(
                      color: AppColors.mediumPink,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 28.h),
                itemCount: state.visibleBeds.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 7.w,
                  mainAxisSpacing: 9.h,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final bed = state.visibleBeds[index];
                  return _AnimatedBedTile(
                    key: ValueKey('${state.filter}-${bed.bedId}'),
                    bed: bed,
                    workflow: appointmentTimers.forBed(bed.bedId),
                    index: index,
                    onTap: () => _showBedActions(context, ref, bed),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BedMatrixState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    'Bed matrix',
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
                Icons.grid_view_rounded,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        Row(
          children: [
            Expanded(
              child: _CounterPill(
                label: 'Occupied',
                value: state.occupiedCount,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _CounterPill(
                label: 'Vacant',
                value: state.vacantCount,
                color: AppColors.mediumPink,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _CounterPill(
                label: 'Sanitizing',
                value: state.sanitizingCount,
                color: AppColors.lightCoral,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(BedMatrixState state, BedMatrixController controller) {
    final filters = <(BedMatrixFilter, String)>[
      (BedMatrixFilter.all, 'All'),
      (BedMatrixFilter.occupied, 'Occupied'),
      (BedMatrixFilter.vacant, 'Vacant'),
      (BedMatrixFilter.sanitizing, 'Sanitizing'),
    ];
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.$1 == state.filter;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDark : AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected ? AppColors.primaryDark : AppColors.lightCoral,
              ),
            ),
            child: InkWell(
              onTap: () => controller.setFilter(filter.$1),
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: selected
                          ? AppColors.white
                          : AppColors.secondaryRed,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(filter.$2),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBedActions(
    BuildContext context,
    WidgetRef ref,
    BedModel bed,
  ) async {
    final controller = ref.read(bedMatrixControllerProvider.notifier);
    if (bed.status == BedStatus.occupied || bed.status == BedStatus.alert) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminActiveSessionView(bedId: bed.bedId),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BedActionSheet(
        bed: bed,
        onAssign: (patientName, nurse) {
          controller.assignPatient(
            bedId: bed.bedId,
            patientName: patientName,
            assignedNurse: nurse,
          );
        },
        onSanitize: () => controller.setSanitizing(bed.bedId),
        onVacant: () => controller.setVacant(bed.bedId),
        onAlert: () => controller.triggerAlert(bed.bedId),
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            height: 8.r,
            width: 8.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.mediumPink, fontSize: 10.sp),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBedTile extends StatefulWidget {
  const _AnimatedBedTile({
    super.key,
    required this.bed,
    required this.workflow,
    required this.index,
    required this.onTap,
  });

  final BedModel bed;
  final AppointmentTimerSnapshot? workflow;
  final int index;
  final VoidCallback onTap;

  @override
  State<_AnimatedBedTile> createState() => _AnimatedBedTileState();
}

class _AnimatedBedTileState extends State<_AnimatedBedTile>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  bool _pressed = false;
  late final AnimationController _alertPulse;

  @override
  void initState() {
    super.initState();
    _alertPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    if (widget.bed.status == BedStatus.alert) _alertPulse.repeat(reverse: true);
    Future<void>.delayed(Duration(milliseconds: 35 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _alertPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.12),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedBuilder(
              animation: _alertPulse,
              builder: (context, _) => _BedCard(
                bed: widget.bed,
                workflow: widget.workflow,
                alertPulse: _alertPulse.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BedCard extends StatelessWidget {
  const _BedCard({
    required this.bed,
    required this.workflow,
    required this.alertPulse,
  });

  final BedModel bed;
  final AppointmentTimerSnapshot? workflow;
  final double alertPulse;

  @override
  Widget build(BuildContext context) {
    final style = _bedStyle(bed.status);
    final isAlert = bed.status == BedStatus.alert;
    final isPreparing = workflow?.isWithin30Minutes ?? false;
    final hasOverlap = workflow?.hasOverlap ?? false;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.all(7.r),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: isAlert || isPreparing
              ? Color.lerp(
                  AppColors.secondaryRed,
                  AppColors.lightCoral,
                  alertPulse,
                )!
              : style.border,
          width: isAlert || isPreparing ? 1.5 + (alertPulse * 1.5) : 1,
        ),
        boxShadow: isAlert || isPreparing
            ? [
                BoxShadow(
                  color: AppColors.secondaryRed.withValues(
                    alpha: 0.12 + alertPulse * 0.12,
                  ),
                  blurRadius: 7.r + alertPulse * 5.r,
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(style.icon, color: style.foreground, size: 20.r),
            SizedBox(height: 4.h),
            Text(
              bed.bedId.replaceFirst('Bed ', '#'),
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              _statusLabel(bed.status),
              style: TextStyle(
                color: style.foreground,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isPreparing)
              Text(
                'Preparing Next Patient\n(In 30m)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.secondaryRed,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (hasOverlap)
              Text(
                '${bed.bedId} active - ${bed.remainingMinutes ?? 30}m\n${bed.patientName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BedStyle {
  const _BedStyle(this.background, this.border, this.foreground, this.icon);

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}

_BedStyle _bedStyle(BedStatus status) {
  return switch (status) {
    BedStatus.occupied => const _BedStyle(
      AppColors.softPinkBg,
      AppColors.lightCoral,
      AppColors.primaryDark,
      Icons.person_outline,
    ),
    BedStatus.sanitizing => const _BedStyle(
      AppColors.lightCoral,
      AppColors.mediumPink,
      AppColors.primaryDark,
      Icons.cleaning_services_outlined,
    ),
    BedStatus.vacant => const _BedStyle(
      AppColors.white,
      AppColors.lightCoral,
      AppColors.mediumPink,
      Icons.bed_outlined,
    ),
    BedStatus.alert => const _BedStyle(
      AppColors.softPinkBg,
      AppColors.secondaryRed,
      AppColors.secondaryRed,
      Icons.warning_amber_rounded,
    ),
    BedStatus.delayed => const _BedStyle(
      AppColors.lightCoral,
      AppColors.secondaryRed,
      AppColors.secondaryRed,
      Icons.hourglass_top_outlined,
    ),
  };
}

String _statusLabel(BedStatus status) {
  return switch (status) {
    BedStatus.occupied => 'Active',
    BedStatus.sanitizing => 'Clean',
    BedStatus.vacant => 'Vacant',
    BedStatus.alert => 'Alert',
    BedStatus.delayed => 'Delayed',
  };
}

class _BedActionSheet extends StatefulWidget {
  const _BedActionSheet({
    required this.bed,
    required this.onAssign,
    required this.onSanitize,
    required this.onVacant,
    required this.onAlert,
  });

  final BedModel bed;
  final void Function(String patientName, String nurse) onAssign;
  final VoidCallback onSanitize;
  final VoidCallback onVacant;
  final VoidCallback onAlert;

  @override
  State<_BedActionSheet> createState() => _BedActionSheetState();
}

class _BedActionSheetState extends State<_BedActionSheet> {
  final _patientController = TextEditingController();
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _patientController.text = widget.bed.patientName ?? '';
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _patientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bed = widget.bed;
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.softPinkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
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
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bed.bedId,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(status: bed.status),
                  ],
                ),
                SizedBox(height: 18.h),
                _metrics(bed),
                SizedBox(height: 18.h),
                Text(
                  'Quick actions',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _patientController,
                  decoration: const InputDecoration(
                    hintText: 'Patient name for assignment',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                SizedBox(height: 10.h),
                _actionButton(
                  'Assign Patient',
                  Icons.person_add_alt_1,
                  AppColors.primaryDark,
                  () {
                    final name = _patientController.text.trim();
                    if (name.isEmpty) return;
                    widget.onAssign(name, 'Nurse on duty');
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 8.h),
                _actionButton(
                  'Mark as Sanitizing',
                  Icons.cleaning_services_outlined,
                  AppColors.mediumPink,
                  () {
                    widget.onSanitize();
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 8.h),
                _actionButton(
                  'Set Vacant',
                  Icons.bed_outlined,
                  AppColors.secondaryRed,
                  () {
                    widget.onVacant();
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 8.h),
                _actionButton(
                  'Trigger Alert',
                  Icons.warning_amber_rounded,
                  AppColors.secondaryRed,
                  () {
                    widget.onAlert();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metrics(BedModel bed) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          _metricRow(
            Icons.person_outline,
            'Patient',
            bed.patientName ?? 'Unassigned',
          ),
          _metricRow(
            Icons.badge_outlined,
            'Assigned nurse',
            bed.assignedNurse ?? 'Not assigned',
          ),
          _metricRow(
            Icons.timer_outlined,
            'Session',
            bed.elapsedMinutes == null
                ? 'No active session'
                : '${bed.elapsedMinutes} min elapsed · ${bed.remainingMinutes} min left',
          ),
        ],
      ),
    );
  }

  Widget _metricRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryRed, size: 19.r),
          SizedBox(width: 10.w),
          Text(
            '$label: ',
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19.r),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.45)),
          padding: EdgeInsets.symmetric(vertical: 13.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.r),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BedStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BedStatus.occupied => AppColors.primaryDark,
      BedStatus.sanitizing => AppColors.mediumPink,
      BedStatus.vacant => AppColors.secondaryRed,
      BedStatus.alert => AppColors.secondaryRed,
      BedStatus.delayed => AppColors.secondaryRed,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
