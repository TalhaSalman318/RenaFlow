import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../models/patient_profile_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.profile});

  final PatientProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.medium.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mediumPink),
              ),
              SizedBox(height: 4.h),
              Text(
                'Your care dashboard',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppSpacing.large.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.medium.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(AppRadii.panel.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile ready',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your RenalFlow care plan is set up.',
                      style: TextStyle(
                        color: AppColors.softPinkBg,
                        fontSize: 14.sp,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.medium.h),
              Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                      context,
                      'Dry weight',
                      '${profile.dryWeight} kg',
                      Icons.monitor_weight_outlined,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _summaryTile(
                      context,
                      'Baseline BP',
                      '${profile.baselineSystolic}/${profile.baselineDiastolic}',
                      Icons.favorite_border,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.medium.h),
              Text(
                'Care team',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.h),
              _detailRow(
                Icons.medical_information_outlined,
                'Nephrologist',
                profile.nephrologistName,
              ),
              _detailRow(
                Icons.contact_phone_outlined,
                'Emergency contact',
                profile.emergencyContact,
              ),
              _detailRow(
                Icons.hub_outlined,
                'Vascular access',
                profile.vascularAccessType,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondaryRed, size: 20.r),
          SizedBox(height: AppSpacing.small.h),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.mediumPink),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xsmall.h),
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
