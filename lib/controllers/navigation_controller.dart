import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppMode { patient, adminNurse }

class NavigationState {
  const NavigationState({this.mode = AppMode.patient, this.activeIndex = 0});

  final AppMode mode;
  final int activeIndex;

  NavigationState copyWith({AppMode? mode, int? activeIndex}) {
    return NavigationState(
      mode: mode ?? this.mode,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController() : super(const NavigationState());

  void setIndex(int index) {
    state = state.copyWith(activeIndex: index);
  }

  void switchMode(AppMode mode) {
    state = state.copyWith(mode: mode, activeIndex: 0);
  }

  void toggleMode() {
    switchMode(
      state.mode == AppMode.patient ? AppMode.adminNurse : AppMode.patient,
    );
  }
}

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationState>(
      (ref) => NavigationController(),
    );
