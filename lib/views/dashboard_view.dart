import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../models/patient_profile_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.profile});

  final PatientProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: TextStyle(color: AppColors.mediumPink, fontSize: 14.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                'Your care dashboard',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 28.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile ready',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your RenalFlow care plan is set up.',
                      style: TextStyle(
                        color: AppColors.softPinkBg,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _summaryTile(
                      'Dry weight',
                      '${profile.dryWeight} kg',
                      Icons.monitor_weight_outlined,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _summaryTile(
                      'Baseline BP',
                      '${profile.baselineSystolic}/${profile.baselineDiastolic}',
                      Icons.favorite_border,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Care team',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
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

  Widget _summaryTile(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondaryRed, size: 22.r),
          SizedBox(height: 14.h),
          Text(
            label,
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 22.r),
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
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
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
