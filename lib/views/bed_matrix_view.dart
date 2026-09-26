import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../controllers/admin_patient_controller.dart';
import '../controllers/bed_matrix_controller.dart';
import '../controllers/appointment_timer_controller.dart';
import '../models/bed_model.dart';
import '../models/patient_model.dart';
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.medium.w,
                20.h,
                AppSpacing.medium.w,
                0,
              ),
              child: _buildHeader(context, state),
            ),
            SizedBox(height: 18.h),
            _buildFilters(state, controller),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium.w),
              child: Row(
                children: [
                  Text(
                    'Bed matrix',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${state.visibleBeds.length} shown',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.mediumPink,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 1100 ? 4 : 6;
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.medium.w,
                      0,
                      AppSpacing.medium.w,
                      AppSpacing.large.h,
                    ),
                    itemCount: state.visibleBeds.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.xsmall.w,
                      mainAxisSpacing: AppSpacing.xsmall.h,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BedMatrixState state) {
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mediumPink,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Bed matrix',
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
    final hasScheduledShifts = bed.shiftSlots.any(
      (slot) => slot.assignments.isNotEmpty,
    );
    if ((bed.status == BedStatus.occupied || bed.status == BedStatus.alert) &&
        !hasScheduledShifts) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminActiveSessionView(bedId: bed.bedId),
        ),
      );
      return;
    }
    final patientsController = ref.read(
      adminPatientControllerProvider.notifier,
    );
    await patientsController.refresh();
    if (!context.mounted) return;
    final patients = ref.read(adminPatientControllerProvider).patients;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BedActionSheet(
        bed: bed,
        patients: patients,
        onAssign: (patientId, selectedDays, shift) async {
          await controller.schedulePatient(
            bedId: bed.bedId,
            patientId: patientId,
            selectedDays: selectedDays,
            shift: shift,
          );
          await patientsController.refresh();
        },
        onUnassign: (scheduleId) async {
          await controller.unassignSchedule(scheduleId: scheduleId);
          await patientsController.refresh();
        },
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
    BedStatus.vacant => 'Vacant',
    BedStatus.alert => 'Alert',
    BedStatus.delayed => 'Delayed',
  };
}

class _BedActionSheet extends StatefulWidget {
  const _BedActionSheet({
    required this.bed,
    required this.patients,
    required this.onAssign,
    required this.onUnassign,
    required this.onVacant,
    required this.onAlert,
  });

  final BedModel bed;
  final List<PatientModel> patients;
  final Future<void> Function(
    String patientId,
    List<int> selectedDays,
    String shift,
  )
  onAssign;
  final Future<void> Function(String scheduleId) onUnassign;
  final VoidCallback onVacant;
  final VoidCallback onAlert;

  @override
  State<_BedActionSheet> createState() => _BedActionSheetState();
}

class _BedActionSheetState extends State<_BedActionSheet> {
  bool _visible = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedPatientId;
  final Set<int> _selectedDays = {DateTime.now().weekday};
  int _selectedDay = DateTime.now().weekday == 7 ? 7 : DateTime.now().weekday;
  String? _selectedShift;
  final Set<String> _expandedShifts = {};

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patients.isEmpty
        ? null
        : widget.patients.first.id;
    final firstAvailable = widget.bed.shiftSlots.firstWhere(
      (slot) => !slot.isAssigned,
      orElse: () => widget.bed.shiftSlots.first,
    );
    _selectedShift = firstAvailable.shift;
    if (widget.bed.shiftSlots.isNotEmpty) {
      _expandedShifts.add(widget.bed.shiftSlots.first.shift);
    }
    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _assignSelected() async {
    final patientId = _selectedPatientId;
    final shift = _selectedShift;
    if (_isSaving ||
        patientId == null ||
        shift == null ||
        _selectedDays.isEmpty) {
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onAssign(patientId, _selectedDays.toList()..sort(), shift);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _selectOpenDay(String shift, int day) {
    setState(() {
      _selectedShift = shift;
      _selectedDay = day;
      _selectedDays
        ..clear()
        ..add(day);
      _expandedShifts.add(shift);
    });
  }

  Future<void> _unassignSchedule(String scheduleId) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onUnassign(scheduleId);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  String _dayLabel(int day) => switch (day) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    _ => 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    final bed = widget.bed;
    final occupiedSlots = bed.occupiedSlots;
    final availableSlots = bed.availableSlots;

    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: EdgeInsets.only(top: 32.h),
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
                _DaySelectorBar(
                  selectedDay: _selectedDay,
                  onChanged: (day) => setState(() => _selectedDay = day),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$occupiedSlots/3 Slots Occupied - $availableSlots Slots Available',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softPinkBg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${_dayLabel(_selectedDay)} selected',
                          style: TextStyle(
                            color: AppColors.secondaryRed,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                ...bed.shiftSlots.map(
                  (slot) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _ShiftDailyCard(
                      slot: slot,
                      selectedDay: _selectedDay,
                      isExpanded: _expandedShifts.contains(slot.shift),
                      isSelected: _selectedShift == slot.shift,
                      onToggle: () => setState(() {
                        if (_expandedShifts.contains(slot.shift)) {
                          _expandedShifts.remove(slot.shift);
                        } else {
                          _expandedShifts.add(slot.shift);
                        }
                        _selectedShift = slot.shift;
                      }),
                      onSelectOpenDay: (day) => _selectOpenDay(slot.shift, day),
                      onUnassign: _unassignSchedule,
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Schedule patient',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10.h),
                if (widget.patients.isEmpty)
                  const Text('No registered patients are available.')
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPatientId,
                    decoration: const InputDecoration(
                      labelText: 'Patient',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: widget.patients
                        .map(
                          (patient) => DropdownMenuItem(
                            value: patient.id,
                            child: Text(
                              '${patient.name} · ${patient.medicalId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPatientId = value),
                  ),
                SizedBox(height: 10.h),
                Text(
                  'Recurring days',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final selected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(_dayLabel(day)),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        value
                            ? _selectedDays.add(day)
                            : _selectedDays.remove(day);
                      }),
                    );
                  }),
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.secondaryRed,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                _actionButton(
                  _isSaving ? 'Saving schedule...' : 'Save Schedule',
                  Icons.person_add_alt_1,
                  AppColors.primaryDark,
                  _assignSelected,
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

class _DaySelectorBar extends StatelessWidget {
  const _DaySelectorBar({required this.selectedDay, required this.onChanged});

  final int selectedDay;
  final ValueChanged<int> onChanged;

  static const List<int> _days = [1, 2, 3, 4, 5, 6, 7];

  String _label(int day) => switch (day) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    _ => 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = selectedDay == day;
          return GestureDetector(
            onTap: () => onChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.lightCoral,
                ),
              ),
              child: Center(
                child: Text(
                  _label(day),
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShiftDailyCard extends StatelessWidget {
  const _ShiftDailyCard({
    required this.slot,
    required this.selectedDay,
    required this.isExpanded,
    required this.isSelected,
    required this.onToggle,
    required this.onSelectOpenDay,
    required this.onUnassign,
  });

  final BedShiftSlot slot;
  final int selectedDay;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectOpenDay;
  final Future<void> Function(String scheduleId) onUnassign;

  String _labelForDay(int day) => switch (day) {
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    6 => 'Sat',
    _ => 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    final hasAssignedForSelectedDay = slot.hasPatientForDay(selectedDay);
    final selectedDayLabel = _labelForDay(selectedDay);
    final selectedAssignment = slot.assignmentForDay(selectedDay);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasAssignedForSelectedDay
              ? AppColors.secondaryRed
              : AppColors.mediumPink,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14.r),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.label,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        slot.timeRange,
                        style: TextStyle(
                          color: AppColors.mediumPink,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: hasAssignedForSelectedDay
                        ? AppColors.secondaryRed.withValues(alpha: 0.12)
                        : AppColors.mediumPink.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    hasAssignedForSelectedDay ? 'Occupied' : 'Vacant',
                    style: TextStyle(
                      color: hasAssignedForSelectedDay
                          ? AppColors.secondaryRed
                          : AppColors.primaryDark,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: hasAssignedForSelectedDay
                  ? AppColors.softPinkBg
                  : AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: hasAssignedForSelectedDay
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient: ${selectedAssignment?.patientName ?? slot.patientName ?? 'Unknown'} (${selectedAssignment?.medicalId ?? slot.medicalId ?? 'N/A'})',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        'Scheduled | ${selectedAssignment?.phone ?? slot.phone ?? 'Phone unavailable'} · ${selectedAssignment?.gender ?? slot.gender ?? 'Gender unavailable'} · ${selectedAssignment?.bloodGroup ?? slot.bloodGroup ?? 'Blood group unavailable'}',
                        style: TextStyle(
                          color: AppColors.secondaryRed,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Vacant for $selectedDayLabel',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(top: 14.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.softPinkBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final label = _labelForDay(day);
                  final scheduled = slot.hasPatientForDay(day);
                  final assignment = slot.assignmentForDay(day);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Material(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      child: InkWell(
                        onTap: scheduled ? null : () => onSelectOpenDay(day),
                        borderRadius: BorderRadius.circular(10.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36.w,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: scheduled
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${assignment?.patientName ?? slot.patientName ?? 'Patient'} (${assignment?.medicalId ?? slot.medicalId ?? 'N/A'})',
                                            style: TextStyle(
                                              color: AppColors.secondaryRed,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                          Text(
                                            '${assignment?.phone ?? slot.phone ?? 'Phone unavailable'} · ${assignment?.gender ?? slot.gender ?? 'Gender unavailable'} · ${assignment?.bloodGroup ?? slot.bloodGroup ?? 'Blood group unavailable'}',
                                            style: TextStyle(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 9.sp,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Vacant - Open',
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: scheduled
                                      ? AppColors.secondaryRed.withValues(
                                          alpha: 0.12,
                                        )
                                      : AppColors.mediumPink.withValues(
                                          alpha: 0.10,
                                        ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  scheduled ? 'Booked' : 'Open',
                                  style: TextStyle(
                                    color: scheduled
                                        ? AppColors.secondaryRed
                                        : AppColors.primaryDark,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (scheduled && assignment?.scheduleId != null)
                                IconButton(
                                  tooltip: 'Unassign patient',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      onUnassign(assignment!.scheduleId!),
                                  icon: const Icon(Icons.person_remove_alt_1),
                                  color: AppColors.secondaryRed,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
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
