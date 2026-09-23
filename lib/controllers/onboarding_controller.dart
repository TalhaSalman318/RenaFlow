import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_profile_model.dart';

class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.vascularAccessType,
    this.dryWeight = '',
    this.baselineSystolic = '',
    this.baselineDiastolic = '',
    this.emergencyContact = '',
    this.nephrologistName = '',
    this.errors = const {},
    this.isLoading = false,
  });

  final int currentStep;
  final String? vascularAccessType;
  final String dryWeight;
  final String baselineSystolic;
  final String baselineDiastolic;
  final String emergencyContact;
  final String nephrologistName;
  final Map<String, String> errors;
  final bool isLoading;

  double get progress => (currentStep + 1) / 2;

  OnboardingState copyWith({
    int? currentStep,
    String? vascularAccessType,
    bool clearVascularAccessType = false,
    String? dryWeight,
    String? baselineSystolic,
    String? baselineDiastolic,
    String? emergencyContact,
    String? nephrologistName,
    Map<String, String>? errors,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      vascularAccessType: clearVascularAccessType
          ? null
          : vascularAccessType ?? this.vascularAccessType,
      dryWeight: dryWeight ?? this.dryWeight,
      baselineSystolic: baselineSystolic ?? this.baselineSystolic,
      baselineDiastolic: baselineDiastolic ?? this.baselineDiastolic,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      nephrologistName: nephrologistName ?? this.nephrologistName,
      errors: errors ?? this.errors,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void setVascularAccess(String value) {
    state = state.copyWith(
      vascularAccessType: value,
      errors: _withoutError('vascularAccessType'),
    );
  }

  void setDryWeight(String value) {
    state = state.copyWith(
      dryWeight: value,
      errors: _withoutError('dryWeight'),
    );
  }

  void setBaselineSystolic(String value) {
    state = state.copyWith(
      baselineSystolic: value,
      errors: _withoutError('baselineSystolic'),
    );
  }

  void setBaselineDiastolic(String value) {
    state = state.copyWith(
      baselineDiastolic: value,
      errors: _withoutError('baselineDiastolic'),
    );
  }

  void setEmergencyContact(String value) {
    state = state.copyWith(
      emergencyContact: value,
      errors: _withoutError('emergencyContact'),
    );
  }

  void setNephrologistName(String value) {
    state = state.copyWith(
      nephrologistName: value,
      errors: _withoutError('nephrologistName'),
    );
  }

  bool nextStep() {
    if (state.currentStep == 0) {
      if (!_validateMedicalDetails()) return false;
      state = state.copyWith(currentStep: 1, errors: {});
      return true;
    }
    return _validateEmergencyDetails();
  }

  void previousStep() {
    if (state.currentStep == 0) return;
    state = state.copyWith(currentStep: state.currentStep - 1, errors: {});
  }

  Future<PatientProfileModel?> complete() async {
    if (!_validateEmergencyDetails()) return null;
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final profile = PatientProfileModel(
      vascularAccessType: state.vascularAccessType!,
      dryWeight: double.parse(state.dryWeight),
      baselineSystolic: int.parse(state.baselineSystolic),
      baselineDiastolic: int.parse(state.baselineDiastolic),
      emergencyContact: state.emergencyContact.trim(),
      nephrologistName: state.nephrologistName.trim(),
    );
    state = state.copyWith(isLoading: false);
    return profile;
  }

  bool _validateMedicalDetails() {
    final errors = <String, String>{};
    if (state.vascularAccessType == null) {
      errors['vascularAccessType'] = 'Select a vascular access type';
    }
    if (!_isPositiveNumber(state.dryWeight)) {
      errors['dryWeight'] = 'Enter a valid dry weight';
    }
    if (!_isInRange(state.baselineSystolic, 60, 250)) {
      errors['baselineSystolic'] = 'Enter a valid systolic value';
    }
    if (!_isInRange(state.baselineDiastolic, 40, 150)) {
      errors['baselineDiastolic'] = 'Enter a valid diastolic value';
    }
    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  bool _validateEmergencyDetails() {
    final errors = <String, String>{};
    if (state.emergencyContact.trim().isEmpty) {
      errors['emergencyContact'] = 'Enter an emergency contact';
    }
    if (state.nephrologistName.trim().isEmpty) {
      errors['nephrologistName'] = 'Enter your nephrologist name';
    }
    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  bool _isPositiveNumber(String value) {
    final number = double.tryParse(value);
    return number != null && number > 0;
  }

  bool _isInRange(String value, int minimum, int maximum) {
    final number = int.tryParse(value);
    return number != null && number >= minimum && number <= maximum;
  }

  Map<String, String> _withoutError(String key) {
    return Map<String, String>.from(state.errors)..remove(key);
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
      (ref) => OnboardingController(),
    );
