import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/constants/app_colors.dart';
import '../app/theme/app_theme.dart';
import '../controllers/patient_portal_controller.dart';
import '../models/patient_portal_model.dart';
import '../controllers/session_history_controller.dart';
import '../models/session_log_model.dart';

class PatientPortalHistoryView extends ConsumerWidget {
  const PatientPortalHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portal = ref.watch(patientPortalControllerProvider);
    final sessions = portal.sessions;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.medium.w,
                AppSpacing.medium.h,
                AppSpacing.medium.w,
                AppSpacing.medium.h,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dialysis history',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    SizedBox(height: AppSpacing.xsmall.h),
                    Text(
                      'Your sessions and treatment status.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumPink,
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium.h),
                    if (portal.isHistoryLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (portal.historyError != null)
                      Text(
                        portal.historyError!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryRed,
                        ),
                      )
                    else if (sessions.isEmpty)
                      Text(
                        'No dialysis sessions have been recorded yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mediumPink,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!portal.isHistoryLoading &&
                portal.historyError == null &&
                sessions.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.medium.w,
                  0,
                  AppSpacing.medium.w,
                  AppSpacing.large.h,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _sessionCard(context, sessions[index]),
                    childCount: sessions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard(BuildContext context, PatientSessionHistoryItem session) {
    final isCompleted = session.status.toLowerCase() == 'completed';
    final statusColor = isCompleted
        ? AppColors.primaryDark
        : AppColors.secondaryRed;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xsmall.h),
      padding: EdgeInsets.all(AppSpacing.medium.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card.r),
        border: Border.all(color: AppColors.lightCoral.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(session.startTime ?? session.endTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Text(
                session.statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: statusColor),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Start ${_formatTime(session.startTime)}  ·  End ${_formatTime(session.endTime)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mediumPink),
          ),
          if (session.bedId != null) ...[
            SizedBox(height: 4.h),
            Text(
              session.bedId!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.primaryDark),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '—';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class SessionHistoryView extends ConsumerStatefulWidget {
  const SessionHistoryView({super.key});

  @override
  ConsumerState<SessionHistoryView> createState() => _SessionHistoryViewState();
}

class _SessionHistoryViewState extends ConsumerState<SessionHistoryView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionHistoryControllerProvider);
    final controller = ref.read(sessionHistoryControllerProvider.notifier);
    final sessions = state.visibleSessions;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              sliver: SliverToBoxAdapter(child: _buildHeader()),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: controller.setSearchQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search clinic or session ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              controller.setSearchQuery('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(top: 14.h),
              sliver: SliverToBoxAdapter(
                child: _buildFilterBar(state, controller),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 28.h),
              sliver: sessions.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _AnimatedSessionItem(
                          key: ValueKey(sessions[index].sessionId),
                          session: sessions[index],
                          index: index,
                          onTap: () => _showSessionDetails(sessions[index]),
                        ),
                        childCount: sessions.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primaryDark,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 40.r),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session history',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Your dialysis journey, at a glance',
                style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
              ),
            ],
          ),
        ),
        Container(
          height: 42.r,
          width: 42.r,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: const Icon(
            Icons.insights_outlined,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    SessionHistoryState state,
    SessionHistoryController controller,
  ) {
    final options = <(SessionHistoryFilter, String)>[
      (SessionHistoryFilter.all, 'All'),
      (SessionHistoryFilter.last7Days, 'Last 7 days'),
      (SessionHistoryFilter.last30Days, 'Last 30 days'),
      (SessionHistoryFilter.highFluidRemoval, 'High fluid removal'),
    ];
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = state.filter == option.$1;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDark : AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected ? AppColors.primaryDark : AppColors.lightCoral,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.14),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              onTap: () => controller.setFilter(option.$1),
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: selected
                          ? AppColors.white
                          : AppColors.secondaryRed,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(option.$2),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 58.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, color: AppColors.lightCoral, size: 42.r),
          SizedBox(height: 12.h),
          Text(
            'No sessions found',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            'Try another search or filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mediumPink, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Future<void> _showSessionDetails(SessionLogModel session) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailSheet(session: session),
    );
  }
}

class _AnimatedSessionItem extends StatefulWidget {
  const _AnimatedSessionItem({
    super.key,
    required this.session,
    required this.index,
    required this.onTap,
  });

  final SessionLogModel session;
  final int index;
  final VoidCallback onTap;

  @override
  State<_AnimatedSessionItem> createState() => _AnimatedSessionItemState();
}

class _AnimatedSessionItemState extends State<_AnimatedSessionItem> {
  bool _visible = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.975 : 1,
              duration: const Duration(milliseconds: 130),
              child: _SessionCard(session: widget.session),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final SessionLogModel session;

  @override
  Widget build(BuildContext context) {
    final meetsTarget = session.ktVScore >= 1.2;
    final statusColor = session.status == SessionStatus.completed
        ? AppColors.primaryDark
        : AppColors.secondaryRed;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightCoral.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            height: 48.r,
            width: 48.r,
            decoration: BoxDecoration(
              color: AppColors.softPinkBg,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.event_available_outlined,
              color: statusColor,
              size: 24.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(session.date),
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${session.clinicLocation} · ${session.durationMinutes} min',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mediumPink,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      '${session.fluidRemoved.toStringAsFixed(1)} L removed',
                      style: TextStyle(
                        color: AppColors.secondaryRed,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      session.status == SessionStatus.completed
                          ? 'Completed'
                          : 'Interrupted',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: meetsTarget ? AppColors.primaryDark : AppColors.softPinkBg,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Column(
              children: [
                Text(
                  'Kt/V',
                  style: TextStyle(
                    color: meetsTarget
                        ? AppColors.white
                        : AppColors.secondaryRed,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  session.ktVScore.toStringAsFixed(2),
                  style: TextStyle(
                    color: meetsTarget
                        ? AppColors.white
                        : AppColors.secondaryRed,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
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

class _SessionDetailSheet extends StatefulWidget {
  const _SessionDetailSheet({required this.session});

  final SessionLogModel session;

  @override
  State<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<_SessionDetailSheet> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final weightRange = (session.preWeight - session.postWeight).clamp(
      0.0,
      session.preWeight,
    );
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.15),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: AppColors.softPinkBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.lightCoral,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session details',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(session.date),
                    style: TextStyle(
                      color: AppColors.secondaryRed,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _detailSection(
                'Weight comparison',
                Column(
                  children: [
                    _weightBar(
                      'Pre-weight',
                      session.preWeight,
                      session.preWeight,
                      AppColors.mediumPink,
                    ),
                    SizedBox(height: 10.h),
                    _weightBar(
                      'Post-weight',
                      session.postWeight,
                      session.preWeight,
                      AppColors.primaryDark,
                    ),
                    SizedBox(height: 12.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${weightRange.toStringAsFixed(1)} kg removed',
                        style: TextStyle(
                          color: AppColors.secondaryRed,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      'Kt/V efficiency',
                      session.ktVScore.toStringAsFixed(2),
                      session.ktVScore >= 1.2,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _metricBox(
                      'Duration',
                      '${session.durationMinutes} min',
                      true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _detailSection(
                'Clinical notes',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoLine(
                      Icons.hub_outlined,
                      'Vascular access',
                      'AV Fistula observed and functioning normally',
                    ),
                    SizedBox(height: 12.h),
                    _infoLine(
                      Icons.notes_outlined,
                      'Care team note',
                      session.status == SessionStatus.completed
                          ? 'Session completed without complications.'
                          : 'Session was interrupted; follow-up recommended.',
                    ),
                    SizedBox(height: 12.h),
                    _infoLine(
                      Icons.location_on_outlined,
                      'Clinic',
                      session.clinicLocation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  Widget _weightBar(String label, double value, double max, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 82.w,
          child: Text(
            label,
            style: TextStyle(color: AppColors.mediumPink, fontSize: 12.sp),
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / max),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12.h,
                backgroundColor: AppColors.softPinkBg,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _metricBox(String label, String value, bool positive) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: positive ? AppColors.primaryDark : AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: positive ? AppColors.softPinkBg : AppColors.mediumPink,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: TextStyle(
              color: positive ? AppColors.white : AppColors.secondaryRed,
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondaryRed, size: 20.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.mediumPink, fontSize: 11.sp),
              ),
              SizedBox(height: 3.h),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
