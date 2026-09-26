import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/constants/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../controllers/session_timer_controller.dart';

class AdminActiveSessionView extends StatelessWidget {
  const AdminActiveSessionView({super.key, required this.bedId});

  final String bedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$bedId session manager')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.medium.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live session control',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: AppSpacing.small.h),
              _AdminSessionTimerSummary(bedId: bedId),
              SizedBox(height: AppSpacing.large.h),
              _AdminSessionActions(bedId: bedId),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSessionTimerSummary extends ConsumerWidget {
  const _AdminSessionTimerSummary({required this.bedId});

  final String bedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(
      sessionTimerControllerProvider.select((timers) => timers[bedId]),
    );
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timer == null ? 'No session is active.' : _statusLabel(timer.status),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.mediumPink),
        ),
        SizedBox(height: AppSpacing.large.h),
        Center(
          child: Text(
            timer == null ? '--:--' : _format(timer.remainingSeconds),
            maxLines: 1,
            style: textTheme.displayLarge?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 48.sp,
            ),
          ),
        ),
        if (timer != null) ...[
          SizedBox(height: AppSpacing.small.h),
          LinearProgressIndicator(
            value: timer.completionPercentage,
            minHeight: 6.h,
            borderRadius: BorderRadius.circular(AppRadii.card.r),
            color: AppColors.secondaryRed,
            backgroundColor: AppColors.lightCoral.withValues(alpha: 0.3),
          ),
          SizedBox(height: AppSpacing.xsmall.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(timer.completionPercentage * 100).round()}% complete',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.mediumPink,
              ),
            ),
          ),
          if (timer.delayMinutes > 0)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.only(top: AppSpacing.xsmall.h),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xsmall.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softPinkBg,
                  borderRadius: BorderRadius.circular(AppRadii.card.r),
                ),
                child: Text(
                  'Delayed (+${timer.delayMinutes} min)',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryRed,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _AdminSessionActions extends ConsumerWidget {
  const _AdminSessionActions({required this.bedId});

  final String bedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandState = ref.watch(
      sessionTimerControllerProvider.select((timers) {
        final timer = timers[bedId];
        return (exists: timer != null, status: timer?.status);
      }),
    );
    final controller = ref.read(sessionTimerControllerProvider.notifier);
    final status = commandState.status;

    if (!commandState.exists || status == SessionTimerStatus.completed) {
      return _button(
        'Start Session',
        Icons.play_arrow,
        () => _runAction(context, () => controller.startSession(bedId)),
      );
    }

    final paused = status == SessionTimerStatus.paused;
    final canControl =
        commandState.exists && status != SessionTimerStatus.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _button(
                paused ? 'Resume' : 'Pause',
                paused ? Icons.play_arrow : Icons.pause,
                canControl
                    ? () => _runAction(
                        context,
                        () => paused
                            ? controller.resumeSession(bedId)
                            : controller.pauseSession(bedId),
                      )
                    : null,
              ),
            ),
            SizedBox(width: AppSpacing.xsmall.w),
            Expanded(
              child: _button(
                'Stop',
                Icons.stop,
                canControl
                    ? () => _runAction(
                        context,
                        () => controller.stopSession(bedId),
                      )
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xsmall.h),
        _button(
          '+15 min delay',
          Icons.more_time,
          canControl
              ? () => _runAction(
                  context,
                  () => controller.addDelay(bedId, 15, 'Clinical delay'),
                )
              : null,
        ),
        SizedBox(height: AppSpacing.xsmall.h),
        _button(
          '+30 min delay',
          Icons.more_time,
          canControl
              ? () => _runAction(
                  context,
                  () => controller.addDelay(bedId, 30, 'Clinical delay'),
                )
              : null,
        ),
      ],
    );
  }
}

Future<void> _runAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update session: $error')),
      );
    }
  }
}

Widget _button(String label, IconData icon, VoidCallback? onPressed) =>
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

String _format(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

String _statusLabel(SessionTimerStatus status) => switch (status) {
  SessionTimerStatus.running => 'Session running',
  SessionTimerStatus.paused => 'Paused for clinical review',
  SessionTimerStatus.delayed => 'Session delayed',
  SessionTimerStatus.completed => 'Session complete',
  SessionTimerStatus.idle => 'Ready to start',
};
