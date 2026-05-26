import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../../core/widgets/tap_scale_wrapper.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/data/progress_repository.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════
// Daily Goal Provider — computes smart daily objectives
// ═══════════════════════════════════════════════════════════════

class DailyGoalState {
  final int goalLessons;
  final int completedToday;
  final int streak;
  final int xp;
  final bool isGoalComplete;

  DailyGoalState({
    required this.goalLessons,
    required this.completedToday,
    required this.streak,
    required this.xp,
    required this.isGoalComplete,
  });

  double get progress =>
      goalLessons > 0 ? (completedToday / goalLessons).clamp(0.0, 1.0) : 0.0;
  int get remaining => (goalLessons - completedToday).clamp(0, goalLessons);
}

final dailyGoalProvider =
    FutureProvider.autoDispose<DailyGoalState>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) {
    return DailyGoalState(
        goalLessons: 2,
        completedToday: 0,
        streak: 0,
        xp: 0,
        isGoalComplete: false);
  }

  // Fetch real data in parallel
  final results = await Future.wait([
    ref.watch(streakProvider.future),
    ref.watch(totalCompletedLessonsProvider.future),
    ref.watch(weeklyProgressProvider.future),
  ]);

  final streak = results[0] as int;
  final totalCompleted = results[1] as int;
  final weeklyActivity = results[2] as List<int>;

  // Today's activity from weekly progress
  final todayIndex = DateTime.now().weekday - 1;
  final completedToday =
      todayIndex < weeklyActivity.length ? weeklyActivity[todayIndex] : 0;

  // Smart goal: base 2, increase by 1 for every 3 days of streak
  final goalLessons = (2 + (streak ~/ 3)).clamp(2, 5);

  // XP calculation: 20 per completed lesson + 10 per streak day
  final xp = (totalCompleted * 20) + (streak * 10);

  return DailyGoalState(
    goalLessons: goalLessons,
    completedToday: completedToday,
    streak: streak,
    xp: xp,
    isGoalComplete: completedToday >= goalLessons,
  );
});

// ═══════════════════════════════════════════════════════════════
// DailyGoalCard Widget
// ═══════════════════════════════════════════════════════════════

class DailyGoalCard extends ConsumerStatefulWidget {
  const DailyGoalCard({super.key});

  @override
  ConsumerState<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends ConsumerState<DailyGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStartNow(BuildContext context) {
    final continueLesson = ref.read(continueLearningProvider).valueOrNull;
    if (continueLesson != null) {
      context.push(
        '/subjects/${Uri.encodeComponent(continueLesson.subjectId)}/lessons/${continueLesson.id}/details',
        extra: {'lesson': continueLesson, 'startPositionSeconds': 0.0},
      );
    } else {
      context.go('/subjects');
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(dailyGoalProvider);
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: goalAsync.when(
            data: (goal) => _buildCard(context, goal, loc, isDark),
            loading: () => _buildLoadingCard(isDark),
            error: (_, __) => _buildCard(
              context,
              DailyGoalState(
                  goalLessons: 2,
                  completedToday: 0,
                  streak: 0,
                  xp: 0,
                  isGoalComplete: false),
              loc,
              isDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, DailyGoalState goal, AppLocalizations loc, bool isDark) {
    final motivationalMsg = _getMotivationalMessage(goal, loc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Goal Card
        TapScaleWrapper(
          onTap: () => _onStartNow(context),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: goal.isGoalComplete
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: (goal.isGoalComplete
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB))
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Goal icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          goal.isGoalComplete ? '🎉' : '🎯',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.dailyGoal,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            motivationalMsg,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Progress section
                Row(
                  children: [
                    // Circular progress
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: goal.progress),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return CustomPaint(
                            painter: _CircularProgressPainter(
                              progress: value,
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              progressColor: Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                '${(value * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${goal.completedToday} / ${goal.goalLessons} ${loc.lessons}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!goal.isGoalComplete)
                            Text(
                              '${loc.remaining}: ${goal.remaining}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              loc.completed,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Start button
                    if (!goal.isGoalComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          loc.startNow,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Streak + XP Row
        Row(
          children: [
            // Streak
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${goal.streak}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Day Streak',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // XP
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6CF7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('⚡', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${goal.xp}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'XP Earned',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }

  String _getMotivationalMessage(DailyGoalState goal, AppLocalizations loc) {
    if (goal.isGoalComplete) return '🎉 ${loc.completed}!';
    final hour = DateTime.now().hour;
    if (hour < 12) return '${goal.goalLessons} ${loc.lessons} today';
    if (hour < 17) return '${goal.remaining} ${loc.remaining}';
    return '${goal.remaining} ${loc.remaining} 🔥';
  }
}

// ═══════════════════════════════════════════════════════════════
// Circular Progress Painter
// ═══════════════════════════════════════════════════════════════

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
