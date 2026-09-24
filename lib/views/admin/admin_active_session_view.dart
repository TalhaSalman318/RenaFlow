import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/constants/app_colors.dart';
import '../../controllers/session_timer_controller.dart';

class AdminActiveSessionView extends ConsumerWidget {
  const AdminActiveSessionView({super.key, required this.bedId});

  final String bedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionTimerControllerProvider)[bedId];
    final controller = ref.read(sessionTimerControllerProvider.notifier);
    final timer = session;
    return Scaffold(
      appBar: AppBar(title: Text('$bedId session manager')),
      body: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live session control',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 25.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              timer == null
                  ? 'No session is active.'
                  : _statusLabel(timer.status),
              style: TextStyle(color: AppColors.mediumPink, fontSize: 14.sp),
            ),
            SizedBox(height: 28.h),
            Center(
              child: Text(
                timer == null ? '--:--' : _format(timer.remainingSeconds),
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 52.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (timer != null && timer.delayMinutes > 0)
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 8.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softPinkBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Delayed (+${timer.delayMinutes} min)',
                    style: TextStyle(
                      color: AppColors.secondaryRed,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 30.h),
            if (timer == null || timer.status == SessionTimerStatus.completed)
              _button(
                'Start Session',
                Icons.play_arrow,
                () => controller.startSession(bedId),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _button(
                      timer.status == SessionTimerStatus.paused
                          ? 'Resume'
                          : 'Pause',
                      timer.status == SessionTimerStatus.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                      () => timer.status == SessionTimerStatus.paused
                          ? controller.resumeSession(bedId)
                          : controller.pauseSession(bedId),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _button(
                      'Stop',
                      Icons.stop,
                      () => controller.stopSession(bedId),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _button(
                '+15 min delay',
                Icons.more_time,
                () => controller.addDelay(bedId, 15, 'Clinical delay'),
              ),
              SizedBox(height: 8.h),
              _button(
                '+30 min delay',
                Icons.more_time,
                () => controller.addDelay(bedId, 30, 'Clinical delay'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _button(String label, IconData icon, VoidCallback onPressed) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
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
}
