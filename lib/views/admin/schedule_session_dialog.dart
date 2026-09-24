import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/constants/app_colors.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/bed_model.dart';
import '../../models/patient_model.dart';
import '../../widgets/app_logo_header.dart';

class ScheduleSessionDialog extends ConsumerStatefulWidget {
  const ScheduleSessionDialog({super.key, required this.patient});

  final PatientModel patient;

  @override
  ConsumerState<ScheduleSessionDialog> createState() =>
      _ScheduleSessionDialogState();
}

class _ScheduleSessionDialogState extends ConsumerState<ScheduleSessionDialog> {
  static const _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final _selectedDays = <String>[];
  String? _selectedShift;
  String? _selectedBed;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(appointmentControllerProvider);
    final controller = ref.read(appointmentControllerProvider.notifier);
    final shifts = _selectedDays.isEmpty
        ? <ShiftAvailability>[]
        : controller.getAvailableShiftsForDays(_selectedDays);
    final beds = _selectedShift == null
        ? <BedModel>[]
        : controller.getAvailableBedsForSlot(_selectedDays, _selectedShift!);
    final step = _selectedDays.isEmpty
        ? 1
        : _selectedShift == null
        ? 2
        : 3;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  color: AppColors.lightCoral,
                ),
              ),
              SizedBox(height: 16.h),
              const AppLogoHeader(compact: true),
              SizedBox(height: 12.h),
              Text(
                'Schedule dialysis session',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${widget.patient.name} · ${widget.patient.medicalId}',
                style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
              ),
              SizedBox(height: 18.h),
              _stepIndicator(step),
              SizedBox(height: 18.h),
              _sectionTitle('1  Select recurring days'),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 7.w,
                runSpacing: 7.h,
                children: _days.map((day) {
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        value
                            ? _selectedDays.add(day)
                            : _selectedDays.remove(day);
                        _selectedShift = null;
                        _selectedBed = null;
                      });
                      controller.setSelectedDays(
                        _selectedDays.map(_dayNumber).toList(),
                      );
                    },
                    selectedColor: AppColors.primaryDark,
                    checkmarkColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.white
                          : AppColors.secondaryRed,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedDays.isEmpty
                    ? _hint('Select one or more days to load available shifts.')
                    : Column(
                        key: const ValueKey('shifts'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          _sectionTitle('2  Available shifts'),
                          SizedBox(height: 8.h),
                          ...shifts.map(
                            (availability) =>
                                _shiftTile(availability, controller),
                          ),
                        ],
                      ),
              ),
              if (_selectedShift != null) ...[
                SizedBox(height: 20.h),
                _sectionTitle('3  Available beds'),
                SizedBox(height: 8.h),
                if (beds.isEmpty)
                  _hint('No beds are available for this day and shift.')
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Wrap(
                      key: ValueKey(beds.map((bed) => bed.bedId).join()),
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: beds.map(_bedTile).toList(),
                    ),
                  ),
              ],
              if (_selectedDays.isNotEmpty &&
                  _selectedShift != null &&
                  _selectedBed != null) ...[
                SizedBox(height: 18.h),
                _summary(),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving || _selectedBed == null ? null : _save,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _saving
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: 22.r,
                            width: 22.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Save schedule', key: ValueKey('save')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(int step) {
    return Row(
      children: List.generate(3, (index) {
        final active = index < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 5.w),
            height: 6.h,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryDark
                  : AppColors.lightCoral.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }),
    );
  }

  Widget _shiftTile(
    ShiftAvailability availability,
    AppointmentController controller,
  ) {
    final selected = _selectedShift == availability.shift;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: availability.isFull
            ? null
            : () {
                setState(() {
                  _selectedShift = availability.shift;
                  _selectedBed = null;
                });
                controller.setSelectedShift(availability.shift);
              },
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.all(13.r),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryDark : AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: availability.isFull
                  ? AppColors.lightCoral
                  : selected
                  ? AppColors.primaryDark
                  : AppColors.lightCoral,
            ),
          ),
          child: Row(
            children: [
              Icon(
                availability.isFull ? Icons.block : Icons.schedule_outlined,
                color: availability.isFull
                    ? AppColors.mediumPink
                    : selected
                    ? AppColors.white
                    : AppColors.primaryDark,
                size: 21.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  availability.shift,
                  style: TextStyle(
                    color: availability.isFull
                        ? AppColors.mediumPink
                        : selected
                        ? AppColors.white
                        : AppColors.primaryDark,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                availability.isFull
                    ? 'Fully Booked'
                    : '${availability.availableBeds} beds free',
                style: TextStyle(
                  color: availability.isFull
                      ? AppColors.secondaryRed
                      : selected
                      ? AppColors.softPinkBg
                      : AppColors.secondaryRed,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bedTile(BedModel bed) {
    final selected = _selectedBed == bed.bedId;
    return ChoiceChip(
      label: Text(bed.bedId),
      selected: selected,
      onSelected: (_) => setState(() => _selectedBed = bed.bedId),
      selectedColor: AppColors.primaryDark,
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.secondaryRed,
        fontSize: 12.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _summary() {
    return Container(
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: AppColors.softPinkBg,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryDark,
            size: 21.r,
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              'Booking ${widget.patient.medicalId} for ${_selectedDays.join(', ')} | ${_selectedShift!.split(' · ').first} Shift | $_selectedBed',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      color: AppColors.primaryDark,
      fontSize: 13.sp,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _hint(String text) => Padding(
    padding: EdgeInsets.only(top: 8.h),
    child: Text(
      text,
      style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
    ),
  );

  int _dayNumber(String day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(day) + 1;

  Future<void> _save() async {
    setState(() => _saving = true);
    final selectedBed = _selectedBed!;
    final shiftHour = _selectedShift!.startsWith('Morning')
        ? 8
        : _selectedShift!.startsWith('Afternoon')
        ? 13
        : 18;
    final endHour = shiftHour + 4;
    try {
      await ref
          .read(appointmentControllerProvider.notifier)
          .schedule(
            patientId: widget.patient.id,
            bedId: selectedBed,
            startTimeLocal: '${shiftHour.toString().padLeft(2, '0')}:00',
            endTimeLocal: '${endHour.toString().padLeft(2, '0')}:00',
          );
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save schedule: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recurring dialysis schedule saved.')),
    );
  }
}
