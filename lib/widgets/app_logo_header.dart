import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({super.key, this.compact = false, this.showCard = true});

  final bool compact;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(compact ? 34.w : 56.w, compact ? 34.w : 56.w),
          painter: _PulseLogoPainter(),
        ),
        SizedBox(width: compact ? 9.w : 13.w),
        Text(
          'RenalFlow',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: compact ? 18.sp : 23.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    if (!showCard) return logo;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: logo,
    );
  }
}

class _PulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.82, ring);
    canvas.drawCircle(
      center,
      radius * 0.62,
      ring..color = AppColors.primaryDark,
    );
    final pulse = Path()
      ..moveTo(size.width * 0.14, center.dy)
      ..lineTo(size.width * 0.32, center.dy)
      ..lineTo(size.width * 0.42, size.height * 0.32)
      ..lineTo(size.width * 0.54, size.height * 0.68)
      ..lineTo(size.width * 0.66, center.dy)
      ..lineTo(size.width * 0.86, center.dy);
    canvas.drawPath(
      pulse,
      Paint()
        ..color = AppColors.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
