import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_log_model.dart';

enum SessionHistoryFilter { all, last7Days, last30Days, highFluidRemoval }

class SessionHistoryState {
  const SessionHistoryState({
    required this.allSessions,
    this.searchQuery = '',
    this.filter = SessionHistoryFilter.all,
  });

  final List<SessionLogModel> allSessions;
  final String searchQuery;
  final SessionHistoryFilter filter;

  List<SessionLogModel> get visibleSessions {
    final now = DateTime.now();
    final query = searchQuery.trim().toLowerCase();
    return allSessions.where((session) {
      final matchesQuery =
          query.isEmpty ||
          session.clinicLocation.toLowerCase().contains(query) ||
          session.sessionId.toLowerCase().contains(query) ||
          _statusLabel(session.status).toLowerCase().contains(query);
      final matchesFilter = switch (filter) {
        SessionHistoryFilter.all => true,
        SessionHistoryFilter.last7Days =>
          now.difference(session.date).inDays <= 7,
        SessionHistoryFilter.last30Days =>
          now.difference(session.date).inDays <= 30,
        SessionHistoryFilter.highFluidRemoval => session.fluidRemoved >= 2.5,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  SessionHistoryState copyWith({
    String? searchQuery,
    SessionHistoryFilter? filter,
  }) {
    return SessionHistoryState(
      allSessions: allSessions,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  static String _statusLabel(SessionStatus status) {
    return status == SessionStatus.completed ? 'completed' : 'interrupted';
  }
}

class SessionHistoryController extends StateNotifier<SessionHistoryState> {
  SessionHistoryController() : super(_initialState);

  static final _initialState = SessionHistoryState(allSessions: _mockSessions);

  static final _mockSessions = <SessionLogModel>[
    SessionLogModel(
      sessionId: 'RF-24018',
      date: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 238,
      preWeight: 71.8,
      postWeight: 69.1,
      fluidRemoved: 2.7,
      ktVScore: 1.42,
      clinicLocation: 'RenalFlow Central Clinic',
      status: SessionStatus.completed,
    ),
    SessionLogModel(
      sessionId: 'RF-24011',
      date: DateTime.now().subtract(const Duration(days: 5)),
      durationMinutes: 224,
      preWeight: 70.9,
      postWeight: 68.8,
      fluidRemoved: 2.1,
      ktVScore: 1.28,
      clinicLocation: 'RenalFlow Central Clinic',
      status: SessionStatus.completed,
    ),
    SessionLogModel(
      sessionId: 'RF-23984',
      date: DateTime.now().subtract(const Duration(days: 12)),
      durationMinutes: 185,
      preWeight: 72.4,
      postWeight: 70.6,
      fluidRemoved: 1.8,
      ktVScore: 1.08,
      clinicLocation: 'RenalFlow Northside',
      status: SessionStatus.interrupted,
    ),
    SessionLogModel(
      sessionId: 'RF-23941',
      date: DateTime.now().subtract(const Duration(days: 28)),
      durationMinutes: 241,
      preWeight: 71.6,
      postWeight: 68.9,
      fluidRemoved: 2.7,
      ktVScore: 1.36,
      clinicLocation: 'RenalFlow Central Clinic',
      status: SessionStatus.completed,
    ),
  ];

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(SessionHistoryFilter filter) {
    state = state.copyWith(filter: filter);
  }
}

final sessionHistoryControllerProvider =
    StateNotifierProvider<SessionHistoryController, SessionHistoryState>(
      (ref) => SessionHistoryController(),
    );
