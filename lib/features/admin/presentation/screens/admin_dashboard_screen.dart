import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/shimmer_loaders.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/live_activity_section.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(adminStatsProvider);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Quick Actions phone grid: derive a per-cell aspect ratio from the real
    // cell width so each card gets enough vertical room for its content
    // (icon bubble + label) — prevents the inner Column from overflowing
    // without hard-coding a card height.
    const _quickActionHPadding = 20.0; // matches the section Padding
    const _quickActionSpacing = 12.0;
    final _quickCellWidth =
        (screenWidth - (_quickActionHPadding * 2) - _quickActionSpacing) / 2;
    const _quickCellHeight = 116.0;
    final _quickActionAspectRatio = _quickCellWidth / _quickCellHeight;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ═══════════════════════════════════════
            // HEADER SECTION
            // ═══════════════════════════════════════
            SliverToBoxAdapter(
              child: _AdminHeader(isDark: isDark, theme: theme),
            ),

            // ═══════════════════════════════════════
            // ANALYTICS CARDS
            // ═══════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _SectionTitle(
                  title: 'Analytics Overview',
                  subtitle: 'Real-time platform metrics',
                  theme: theme,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: statsAsync.when(
                data: (stats) => SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 4 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isTablet ? 1.3 : 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    _StatCard(
                      title: 'Subjects',
                      count: stats.totalSubjects,
                      icon: Icons.category_rounded,
                      gradient: const [Color(0xFFFF6B35), Color(0xFFFF8F65)],
                      shadowColor: const Color(0xFFFF6B35),
                    ),
                    _StatCard(
                      title: 'Lessons',
                      count: stats.totalLessons,
                      icon: Icons.play_lesson_rounded,
                      gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                      shadowColor: const Color(0xFF0EA5E9),
                    ),
                    _StatCard(
                      title: 'Quizzes',
                      count: stats.totalQuizzes,
                      icon: Icons.quiz_rounded,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      shadowColor: const Color(0xFF8B5CF6),
                    ),
                    _StatCard(
                      title: 'Video Views',
                      count: stats.totalVideoProgress,
                      icon: Icons.visibility_rounded,
                      gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                      shadowColor: const Color(0xFF10B981),
                    ),
                  ]),
                ),
                loading: () => SliverToBoxAdapter(
                  child: const ShimmerGridLoader(itemCount: 4, childAspectRatio: 1.05),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: _ErrorCard(theme: theme, message: err.toString()),
                ),
              ),
            ),

            // ═══════════════════════════════════════
            // CHART SECTION
            // ═══════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: _SectionTitle(
                  title: 'Platform Activity',
                  subtitle: 'Quiz completions over time',
                  theme: theme,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: statsAsync.when(
                  data: (stats) => _ChartContainer(
                    theme: theme,
                    isDark: isDark,
                    quizActivity: stats.quizActivity,
                  ),
                  loading: () => const ShimmerChartLoader(height: 220),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ═══════════════════════════════════════
            // QUICK ACTIONS
            // ═══════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: _SectionTitle(
                  title: 'Quick Actions',
                  subtitle: 'Create new content',
                  theme: theme,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: isTablet
                    ? Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Subject',
                              icon: Icons.add_circle_outline_rounded,
                              gradient: const [Color(0xFFFF6B35), Color(0xFFFF8F65)],
                              onTap: () => context.push('/admin/add-subject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Lesson',
                              icon: Icons.video_call_rounded,
                              gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                              onTap: () => context.push('/admin/add-lesson'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Exam',
                              icon: Icons.assignment_add,
                              gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
                              onTap: () => context.push('/admin/add-exam'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              title: 'Quiz',
                              icon: Icons.post_add_rounded,
                              gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                              onTap: () => context.push('/admin/add-quiz'),
                            ),
                          ),
                        ],
                      )
                    : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: _quickActionAspectRatio,
                        children: [
                          _QuickActionCard(
                            title: 'Subject',
                            icon: Icons.add_circle_outline_rounded,
                            gradient: const [Color(0xFFFF6B35), Color(0xFFFF8F65)],
                            onTap: () => context.push('/admin/add-subject'),
                          ),
                          _QuickActionCard(
                            title: 'Lesson',
                            icon: Icons.video_call_rounded,
                            gradient: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                            onTap: () => context.push('/admin/add-lesson'),
                          ),
                          _QuickActionCard(
                            title: 'Exam',
                            icon: Icons.assignment_add,
                            gradient: const [Color(0xFFEC4899), Color(0xFFF472B6)],
                            onTap: () => context.push('/admin/add-exam'),
                          ),
                          _QuickActionCard(
                            title: 'Quiz',
                            icon: Icons.post_add_rounded,
                            gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                            onTap: () => context.push('/admin/add-quiz'),
                          ),
                        ],
                      ),
              ),
            ),

            // ═══════════════════════════════════════
            // LIVE ACTIVITY
            // ═══════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: const LiveActivitySection(),
              ),
            ),

            // ═══════════════════════════════════════
            // CONTENT MANAGEMENT
            // ═══════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: _SectionTitle(
                  title: 'Content Management',
                  subtitle: 'Manage your platform content',
                  theme: theme,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ManagementCard(
                    title: 'Manage Subjects',
                    subtitle: 'Edit or delete subject categories',
                    icon: Icons.category_rounded,
                    accentColor: const Color(0xFFFF6B35),
                    onTap: () => context.push('/admin/manage-subjects'),
                  ),
                  const SizedBox(height: 12),
                  _ManagementCard(
                    title: 'Manage Lessons',
                    subtitle: 'Update videos and materials',
                    icon: Icons.video_library_rounded,
                    accentColor: const Color(0xFF0EA5E9),
                    onTap: () => context.push('/admin/manage-lessons'),
                  ),
                  const SizedBox(height: 12),
                  _ManagementCard(
                    title: 'Manage Quizzes',
                    subtitle: 'Modify questions and settings',
                    icon: Icons.rule_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/admin/manage-quizzes'),
                  ),
                  const SizedBox(height: 12),
                  _ManagementCard(
                    title: 'Manage Exams',
                    subtitle: 'Exams, semesters and PDF models',
                    icon: Icons.assignment_rounded,
                    accentColor: const Color(0xFFEC4899),
                    onTap: () => context.push('/admin/manage-exams'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// _AdminHeader — Gradient header with avatar and greeting
// ═══════════════════════════════════════════════════════════════

class _AdminHeader extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _AdminHeader({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF0F172A)]
              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ═══════════════════════════════════════════════════════════════
// _SectionTitle — Reusable section header with subtitle
// ═══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final ThemeData theme;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _StatCard — Modern gradient analytics card with animation
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatefulWidget {
  final String title;
  final int count;
  final IconData icon;
  final List<Color> gradient;
  final Color shadowColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, size: 22, color: Colors.white),
            ),
            const Spacer(),
            // Title
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Counter
            AnimatedCounter(
              end: widget.count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ChartContainer — Modern chart wrapper with glassmorphism
// ═══════════════════════════════════════════════════════════════

class _ChartContainer extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final List<int> quizActivity;

  const _ChartContainer({
    required this.theme,
    required this.isDark,
    required this.quizActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (quizActivity.isEmpty || quizActivity.every((val) => val == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'No activity data yet',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    double maxVal = quizActivity.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal < 10) maxVal = 10;
    maxVal = maxVal * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                if (value == maxVal) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final idx = value.toInt();
                if (idx >= 0 && idx < days.length) {
                  return Text(
                    days[idx],
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (quizActivity.length - 1).toDouble().clamp(1, double.infinity),
        minY: 0,
        maxY: maxVal,
        lineBarsData: [
          LineChartBarData(
            spots: quizActivity
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: theme.colorScheme.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.25),
                  theme.colorScheme.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.primary,

            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                spot.y.toInt().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _QuickActionCard — Modern action card with gradient icon
// ═══════════════════════════════════════════════════════════════

class _QuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ManagementCard — Premium content management card
// ═══════════════════════════════════════════════════════════════

class _ManagementCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ManagementCard> createState() => _ManagementCardState();
}

class _ManagementCardState extends State<_ManagementCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Accent icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ErrorCard — Styled error state
// ═══════════════════════════════════════════════════════════════

class _ErrorCard extends StatelessWidget {
  final ThemeData theme;
  final String message;

  const _ErrorCard({required this.theme, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load analytics',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

