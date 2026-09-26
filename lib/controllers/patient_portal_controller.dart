import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_portal_model.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_portal_service.dart';
import 'auth_controller.dart';
import 'session_timer_controller.dart';

class PatientPortalState {
  const PatientPortalState({
    this.isLoading = true,
    this.isHistoryLoading = false,
    this.profile,
    this.schedules = const [],
    this.sessions = const [],
    this.error,
    this.historyError,
  });

  final bool isLoading;
  final bool isHistoryLoading;
  final PatientProfileModel? profile;
  final List<PatientPortalSchedule> schedules;
  final List<PatientSessionHistoryItem> sessions;
  final String? error;
  final String? historyError;
}

class PatientPortalController extends StateNotifier<PatientPortalState> {
  PatientPortalController(
    this._ref, {
    required this.authenticatedUserId,
    required this.isAuthenticatedPatient,
  }) : super(const PatientPortalState()) {
    if (authenticatedUserId == null || !isAuthenticatedPatient) {
      state = const PatientPortalState(
        isLoading: false,
        error: 'Sign in with a patient account to view this portal.',
      );
    } else {
      unawaited(load());
    }
  }

  final Ref _ref;
  final String? authenticatedUserId;
  final bool isAuthenticatedPatient;

  Future<void> load() async {
    state = const PatientPortalState(isLoading: true);
    try {
      final portal = await _ref
          .read(patientPortalServiceProvider)
          .fetchPortal();
      if (!mounted) return;
      state = PatientPortalState(
        isLoading: false,
        isHistoryLoading: true,
        profile: portal.profile,
        schedules: portal.schedules,
      );
      unawaited(_hydrateLiveSession(portal.profile));
      try {
        final sessions = await _ref
            .read(patientPortalServiceProvider)
            .fetchSessionHistory(portal.profile.id);
        if (mounted) {
          state = PatientPortalState(
            profile: portal.profile,
            schedules: portal.schedules,
            sessions: sessions,
          );
        }
      } catch (error) {
        if (mounted) {
          state = PatientPortalState(
            profile: portal.profile,
            schedules: portal.schedules,
            historyError: error.toString(),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        state = PatientPortalState(isLoading: false, error: error.toString());
      }
    }
  }

  Future<void> _hydrateLiveSession(PatientProfileModel profile) async {
    if (profile.id.isEmpty || profile.medicalId.isEmpty) return;
    try {
      await _ref
          .read(sessionTimerControllerProvider.notifier)
          .hydratePatientSession(
            patientId: profile.id,
            patientMedicalId: profile.medicalId,
            assignedBedId: profile.assignedBedId,
          );
    } catch (_) {}
  }
}

final patientPortalControllerProvider =
    StateNotifierProvider<PatientPortalController, PatientPortalState>((ref) {
      final auth = ref.watch(authControllerProvider);
      final user = auth.user;
      return PatientPortalController(
        ref,
        authenticatedUserId: user?['id']?.toString(),
        isAuthenticatedPatient: user?['role']?.toString() == 'patient',
      );
    });
