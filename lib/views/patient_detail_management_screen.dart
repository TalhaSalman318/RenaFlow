import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../controllers/admin_patient_controller.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/bed_matrix_controller.dart';
import '../controllers/session_timer_controller.dart';
import '../models/patient_model.dart';
import '../services/api_service.dart';

class PatientDetailManagementScreen extends ConsumerStatefulWidget {
  const PatientDetailManagementScreen({super.key, required this.patient});

  final PatientModel patient;

  @override
  ConsumerState<PatientDetailManagementScreen> createState() =>
      _PatientDetailManagementScreenState();
}

class _PatientDetailManagementScreenState
    extends ConsumerState<PatientDetailManagementScreen> {
  late PatientModel _patient;
  bool _sessionHydrating = true;
  bool _timerActionInProgress = false;
  String? _timerError;
  int _targetMinutes = 240;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_hydrateActiveSession());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beds = ref.watch(bedMatrixControllerProvider).beds;
    final bedChoices =
        <String>{
          '',
          ...beds.map((bed) => bed.bedId),
          if (_patient.assignedBedId?.isNotEmpty ?? false)
            _patient.assignedBedId!,
        }.toList()..sort((first, second) {
          if (first.isEmpty) return -1;
          if (second.isEmpty) return 1;
          return first.compareTo(second);
        });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(_patient.fullName, 'Unknown'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => _editProfile(bedChoices),
            icon: const Icon(Icons.edit_outlined),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth > 1000 ? 920 : double.infinity,
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 600 ? 16.w : 28.w,
                  vertical: 16.h,
                ),
                children: [
                  _buildIdentityHeader(context),
                  SizedBox(height: 16.h),
                  _buildProfileSection(context),
                  SizedBox(height: 16.h),
                  Consumer(
                    builder: (context, ref, _) {
                      final timer = ref.watch(
                        sessionTimerControllerProvider.select(
                          (timers) => _timerForPatient(timers),
                        ),
                      );
                      return _buildTimerCard(context, timer);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadii.panel.r),
      ),
      child: Wrap(
        spacing: 14.w,
        runSpacing: 12.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CircleAvatar(
            radius: 26.r,
            backgroundColor: AppColors.white.withValues(alpha: 0.16),
            child: Icon(
              Icons.person_outline,
              color: AppColors.white,
              size: 28.r,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 320.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(_patient.fullName, 'Unknown'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppColors.white),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Medical ID  ${_text(_patient.medicalId, 'N/A')}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.softPinkBg),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _text(_patient.assignedBedId, 'Unassigned'),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return _SectionSurface(
      title: 'Patient profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoTile(
            context,
            Icons.person_outline,
            'Full name',
            _text(_patient.fullName, 'Unknown'),
          ),
          const Divider(height: 1),
          _infoTile(
            context,
            Icons.phone_outlined,
            'Phone',
            _text(_patient.phone, 'N/A'),
          ),
          const Divider(height: 1),
          _infoTile(
            context,
            Icons.bloodtype_outlined,
            'Blood group',
            _text(_patient.bloodGroup, 'Unknown'),
          ),
          const Divider(height: 1),
          _infoTile(
            context,
            Icons.contact_emergency_outlined,
            'Emergency contact',
            _emergencyContactText,
          ),
          const Divider(height: 1),
          _infoTile(
            context,
            Icons.notes_outlined,
            'Notes',
            _text(_patient.notes, 'None'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4.h),
      horizontalTitleGap: 14.w,
      leading: Icon(icon, color: AppColors.mediumPink, size: 21.r),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.mediumPink),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 3.h),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(BuildContext context, BedSessionTimer? timer) {
    final isPaused = timer?.status == SessionTimerStatus.paused;
    final isRunning =
        timer?.status == SessionTimerStatus.running ||
        timer?.status == SessionTimerStatus.delayed;
    final hasActiveTimer = isPaused || isRunning;
    final bedId = timer?.bedId ?? _patient.assignedBedId ?? '';
    final canStart =
        bedId.isNotEmpty &&
        !hasActiveTimer &&
        !_timerActionInProgress &&
        !_sessionHydrating;

    return _SectionSurface(
      title: 'Dialysis session',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target duration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              DropdownButton<int>(
                value: _targetMinutes,
                items: const [180, 210, 240, 270]
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('${minutes ~/ 60} hours · $minutes min'),
                      ),
                    )
                    .toList(),
                onChanged: hasActiveTimer || _timerActionInProgress
                    ? null
                    : (value) => setState(() => _targetMinutes = value ?? 240),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              SizedBox(
                width: 112.r,
                height: 112.r,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: timer?.completionPercentage ?? 0,
                        strokeWidth: 9.r,
                        backgroundColor: AppColors.softPinkBg,
                        color: AppColors.secondaryRed,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timer == null
                                ? '--:--'
                                : _format(timer.remainingSeconds),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.primaryDark),
                          ),
                          Text(
                            timer == null
                                ? 'Ready'
                                : '${(timer.completionPercentage * 100).round()}%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.mediumPink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timer == null
                          ? _sessionHydrating
                                ? 'Checking session status'
                                : 'Ready for dialysis'
                          : isPaused
                          ? 'Session paused'
                          : timer.status == SessionTimerStatus.completed
                          ? 'Session complete'
                          : 'Session in progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      timer == null
                          ? _sessionHydrating
                                ? 'Loading the latest dialysis session.'
                                : 'No active session for this patient.'
                          : '${_format(timer.elapsedSeconds)} elapsed of ${timer.totalDurationMinutes} min target',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumPink,
                      ),
                    ),
                    if (timer?.delayMinutes case final delay? when delay > 0)
                      Padding(
                        padding: EdgeInsets.only(top: 5.h),
                        child: Text(
                          'Extended by $delay minutes',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.secondaryRed),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: [
              FilledButton.icon(
                onPressed: canStart
                    ? () => _runTimerAction(
                        () => ref
                            .read(sessionTimerControllerProvider.notifier)
                            .startSession(
                              bedId,
                              patientId: _patient.id,
                              patientMedicalId: _patient.medicalId,
                              durationMinutes: _targetMinutes,
                            ),
                      )
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _timerActionInProgress ? 'Updating...' : 'Start Dialysis',
                ),
              ),
              OutlinedButton.icon(
                onPressed: hasActiveTimer && !_timerActionInProgress
                    ? () => _runTimerAction(
                        () => isPaused
                            ? ref
                                  .read(sessionTimerControllerProvider.notifier)
                                  .resumeSession(bedId)
                            : ref
                                  .read(sessionTimerControllerProvider.notifier)
                                  .pauseSession(bedId),
                      )
                    : null,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(isPaused ? 'Resume' : 'Pause'),
              ),
              OutlinedButton.icon(
                onPressed: hasActiveTimer && !_timerActionInProgress
                    ? () => _runTimerAction(
                        () => ref
                            .read(sessionTimerControllerProvider.notifier)
                            .stopSession(bedId),
                      )
                    : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop Session'),
              ),
            ],
          ),
          if (bedId.isEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'Assign a bed before starting dialysis.',
              style: TextStyle(color: AppColors.mediumPink, fontSize: 11.sp),
            ),
          ],
          if (_timerError != null) ...[
            SizedBox(height: 8.h),
            Text(
              _timerError!,
              style: TextStyle(color: AppColors.secondaryRed, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  BedSessionTimer? _timerForPatient(Map<String, BedSessionTimer> timers) {
    final bedId = _patient.assignedBedId;
    var timer = bedId == null ? null : timers[bedId];
    if (timer == null) {
      for (final candidate in timers.values) {
        if (candidate.patientId == _patient.id ||
            candidate.patientMedicalId == _patient.medicalId) {
          timer = candidate;
          break;
        }
      }
    }
    if (timer == null) return null;
    final matchesPatient =
        timer.patientId == _patient.id ||
        timer.patientMedicalId == _patient.medicalId;
    if (matchesPatient ||
        (timer.patientId == null && timer.patientMedicalId == null)) {
      return timer;
    }
    return null;
  }

  Future<void> _hydrateActiveSession() async {
    try {
      await ref
          .read(sessionTimerControllerProvider.notifier)
          .hydratePatientSession(
            patientId: _patient.id,
            patientMedicalId: _patient.medicalId,
            assignedBedId: _patient.assignedBedId,
          );
    } catch (error) {
      if (mounted) setState(() => _timerError = error.toString());
    } finally {
      if (mounted) setState(() => _sessionHydrating = false);
    }
  }

  Future<void> _runTimerAction(Future<void> Function() action) async {
    setState(() {
      _timerActionInProgress = true;
      _timerError = null;
    });
    try {
      await action();
    } catch (error) {
      if (error is ApiException &&
          (error.statusCode == 400 || error.statusCode == 409) &&
          error.message.toLowerCase().contains('already started')) {
        try {
          await ref
              .read(sessionTimerControllerProvider.notifier)
              .hydratePatientSession(
                patientId: _patient.id,
                patientMedicalId: _patient.medicalId,
                assignedBedId: _patient.assignedBedId,
              );
        } catch (_) {}
      } else if (mounted) {
        setState(() => _timerError = error.toString());
      }
    } finally {
      if (mounted) setState(() => _timerActionInProgress = false);
    }
  }

  Future<void> _editProfile(List<String> bedChoices) async {
    final updated = await showDialog<PatientModel>(
      context: context,
      builder: (_) =>
          _PatientProfileEditDialog(patient: _patient, bedChoices: bedChoices),
    );
    if (updated == null || !mounted) return;
    ref
        .read(appointmentControllerProvider.notifier)
        .updatePatientDisplay(updated.id, updated.name);
    setState(() => _patient = updated);
  }

  String get _emergencyContactText {
    final name = _patient.emergencyContactName.trim();
    final phone = _patient.emergencyContactPhone.trim();
    if (name.isEmpty && phone.isEmpty) {
      return _text(_patient.emergencyContact, 'Not provided');
    }
    if (name.isEmpty) return phone;
    if (phone.isEmpty) return name;
    return '$name · $phone';
  }

  String _format(int seconds) =>
      '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  String _text(String? value, String fallback) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? fallback : normalized;
  }
}

class _PatientProfileEditDialog extends ConsumerStatefulWidget {
  const _PatientProfileEditDialog({
    required this.patient,
    required this.bedChoices,
  });

  final PatientModel patient;
  final List<String> bedChoices;

  @override
  ConsumerState<_PatientProfileEditDialog> createState() =>
      _PatientProfileEditDialogState();
}

class _PatientProfileEditDialogState
    extends ConsumerState<_PatientProfileEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _notesController;
  late String _assignedBedId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    final legacyContact = patient.emergencyContact.split(' · ');
    _nameController = TextEditingController(text: patient.fullName);
    _phoneController = TextEditingController(text: patient.phone);
    _bloodGroupController = TextEditingController(text: patient.bloodGroup);
    _contactNameController = TextEditingController(
      text: patient.emergencyContactName.trim().isNotEmpty
          ? patient.emergencyContactName
          : legacyContact.first.trim().isNotEmpty
          ? legacyContact.first.trim()
          : patient.fullName,
    );
    _contactPhoneController = TextEditingController(
      text: patient.emergencyContactPhone.trim().isNotEmpty
          ? patient.emergencyContactPhone
          : legacyContact.length > 1
          ? legacyContact.last.trim()
          : patient.phone,
    );
    _notesController = TextEditingController(text: patient.notes);
    _assignedBedId = patient.assignedBedId ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(adminPatientControllerProvider.notifier)
          .updatePatient(
            patient: widget.patient,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            bloodGroup: _bloodGroupController.text.trim(),
            emergencyContactName: _contactNameController.text.trim(),
            emergencyContactPhone: _contactPhoneController.text.trim(),
            notes: _notesController.text.trim(),
            assignedBedId: _assignedBedId.isEmpty ? null : _assignedBedId,
          );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit patient profile'),
      content: SizedBox(
        width: 480.w,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_nameController, 'Full name', Icons.person_outline),
              _field(_phoneController, 'Phone', Icons.phone_outlined),
              _field(
                _bloodGroupController,
                'Blood group',
                Icons.bloodtype_outlined,
              ),
              _field(
                _contactNameController,
                'Emergency contact name',
                Icons.contact_emergency_outlined,
              ),
              _field(
                _contactPhoneController,
                'Emergency contact phone',
                Icons.call_outlined,
              ),
              _field(_notesController, 'Notes', Icons.notes_outlined, lines: 3),
              DropdownButtonFormField<String>(
                initialValue: _assignedBedId,
                decoration: const InputDecoration(
                  labelText: 'Assigned bed',
                  prefixIcon: Icon(Icons.bed_outlined),
                ),
                items: widget.bedChoices
                    .map(
                      (bedId) => DropdownMenuItem(
                        value: bedId,
                        child: Text(bedId.isEmpty ? 'Unassigned' : bedId),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _assignedBedId = value ?? ''),
              ),
              if (_error != null) ...[
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: AppColors.secondaryRed,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int lines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightCoral.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}
