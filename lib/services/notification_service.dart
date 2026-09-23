import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationState {
  const NotificationState({this.message, this.isVisible = false});

  final String? message;
  final bool isVisible;
}

class NotificationService extends StateNotifier<NotificationState> {
  NotificationService(Ref ref) : super(const NotificationState());
  Timer? _timer;

  void schedulePreSessionAlert({
    required String patientName,
    required DateTime sessionStart,
    required String bedId,
  }) {
    _timer?.cancel();
    final delay = sessionStart
        .subtract(const Duration(minutes: 30))
        .difference(DateTime.now());
    if (delay.isNegative) {
      showAlert(patientName, bedId);
      return;
    }
    _timer = Timer(delay, () => showAlert(patientName, bedId));
  }

  void showAlert(String patientName, String bedId) {
    state = NotificationState(
      message:
          '$patientName: Your session starts in 30 minutes at $bedId. Vehicle dispatched.',
      isVisible: true,
    );
  }

  void dismiss() => state = const NotificationState();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final notificationServiceProvider =
    StateNotifierProvider<NotificationService, NotificationState>(
      (ref) => NotificationService(ref),
    );
