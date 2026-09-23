import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/constants/app_colors.dart';
import '../../controllers/admin_patient_controller.dart';
import '../../models/patient_model.dart';
import '../../widgets/app_logo_header.dart';

class AdminAddPatientView extends ConsumerStatefulWidget {
  const AdminAddPatientView({super.key});

  @override
  ConsumerState<AdminAddPatientView> createState() =>
      _AdminAddPatientViewState();
}

class _AdminAddPatientViewState extends ConsumerState<AdminAddPatientView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _contact = TextEditingController();
  final _emergency = TextEditingController();
  final _dryWeight = TextEditingController();
  final _bp = TextEditingController();
  final _nephrologist = TextEditingController();
  String _gender = 'Female';
  String _vascularAccess = 'AV Fistula';

  @override
  void dispose() {
    for (final controller in [
      _name,
      _age,
      _contact,
      _emergency,
      _dryWeight,
      _bp,
      _nephrologist,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final patient = PatientModel(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      age: int.parse(_age.text),
      gender: _gender,
      medicalId: '',
      dryWeight: double.parse(_dryWeight.text),
      vascularAccess: _vascularAccess,
      baselineBp: _bp.text.trim(),
      nephrologist: _nephrologist.text.trim(),
      emergencyContact: '${_contact.text.trim()} · ${_emergency.text.trim()}',
    );
    await ref.read(adminPatientControllerProvider.notifier).addPatient(patient);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppLogoHeader(compact: true),
        content: Text('${patient.name} was added to patient management.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(adminPatientControllerProvider).isSaving;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 30.h),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.primaryDark,
                  ),
                  const Expanded(
                    child: AppLogoHeader(compact: true, showCard: false),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Text(
                'Add patient profile',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 27.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                'Create a complete clinical record for the care team.',
                style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
              ),
              SizedBox(height: 22.h),
              _section('1  Basic information', [
                _field(_name, 'Full name', Icons.person_outline),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _age,
                        'Age',
                        Icons.cake_outlined,
                        numeric: true,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _dropdown('Gender', _gender, [
                        'Female',
                        'Male',
                        'Other',
                      ], (value) => setState(() => _gender = value!)),
                    ),
                  ],
                ),
                _field(
                  _contact,
                  'Primary contact number',
                  Icons.phone_outlined,
                  numeric: true,
                ),
                _field(
                  _emergency,
                  'Emergency contact',
                  Icons.contact_phone_outlined,
                ),
              ]),
              SizedBox(height: 14.h),
              _section('2  Clinical parameters', [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _dryWeight,
                        'Dry weight (kg)',
                        Icons.monitor_weight_outlined,
                        numeric: true,
                        decimal: true,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _field(_bp, 'Baseline BP', Icons.favorite_border),
                    ),
                  ],
                ),
                _dropdown(
                  'Vascular access',
                  _vascularAccess,
                  ['AV Fistula', 'Catheter'],
                  (value) => setState(() => _vascularAccess = value!),
                ),
                _field(
                  _nephrologist,
                  'Nephrologist name',
                  Icons.medical_information_outlined,
                ),
              ]),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: isSaving
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: 22.r,
                            width: 22.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Save Patient', key: ValueKey('save')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 15.h),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool numeric = false,
    bool decimal = false,
    bool required = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: decimal)
            : null,
        validator: (value) =>
            required && (value == null || value.trim().isEmpty)
            ? 'Required'
            : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.tune_outlined),
        ),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
