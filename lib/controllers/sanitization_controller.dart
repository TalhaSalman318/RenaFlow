import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sanitization_task_model.dart';
import 'bed_matrix_controller.dart';

class SanitizationController
    extends StateNotifier<List<SanitizationTaskModel>> {
  SanitizationController(this._ref) : super(_initialTasks) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final Ref _ref;
  late final Timer _timer;

  static final _initialTasks = [
    const SanitizationTaskModel(
      bedId: 'Bed 13',
      currentStepIndex: 1,
      totalSteps: 3,
      isUvSterilized: true,
      isFilterFlushed: false,
      isLineChanged: false,
      remainingTimeSeconds: 184,
    ),
    const SanitizationTaskModel(
      bedId: 'Bed 14',
      currentStepIndex: 2,
      totalSteps: 3,
      isUvSterilized: true,
      isFilterFlushed: true,
      isLineChanged: false,
      remainingTimeSeconds: 92,
    ),
    const SanitizationTaskModel(
      bedId: 'Bed 15',
      currentStepIndex: 0,
      totalSteps: 3,
      isUvSterilized: false,
      isFilterFlushed: false,
      isLineChanged: false,
      remainingTimeSeconds: 246,
    ),
  ];

  void toggleStep(String bedId, int stepIndex) {
    final task = _findTask(bedId);
    if (task == null) return;
    final values = [
      task.isUvSterilized,
      task.isFilterFlushed,
      task.isLineChanged,
    ];
    values[stepIndex] = !values[stepIndex];
    _updateTask(
      task.copyWith(
        isUvSterilized: values[0],
        isFilterFlushed: values[1],
        isLineChanged: values[2],
        currentStepIndex: values.where((value) => value).length,
      ),
    );
  }

  void _tick() {
    if (!mounted) return;
    for (final task in state) {
      if (task.remainingTimeSeconds <= 0) continue;
      _updateTask(
        task.copyWith(remainingTimeSeconds: task.remainingTimeSeconds - 1),
      );
    }
    for (final task in state) {
      if (task.remainingTimeSeconds <= 0 &&
          task.currentStepIndex == task.totalSteps) {
        _ref.read(bedMatrixControllerProvider.notifier).setVacant(task.bedId);
      }
    }
  }

  SanitizationTaskModel? _findTask(String bedId) {
    for (final task in state) {
      if (task.bedId == bedId) return task;
    }
    return null;
  }

  void _updateTask(SanitizationTaskModel updatedTask) {
    state = [
      for (final task in state)
        if (task.bedId == updatedTask.bedId) updatedTask else task,
    ];
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final sanitizationControllerProvider =
    StateNotifierProvider<SanitizationController, List<SanitizationTaskModel>>(
      (ref) => SanitizationController(ref),
    );
