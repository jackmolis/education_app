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

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface, 
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profiling
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.shield_rounded, size: 32, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                        Text('Administrator', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // --- Analytics Overview ---
                Text('Analytics Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                statsAsync.when(
                  data: (stats) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.1,
                          children: [
                            _buildStatCard(
                              context,
                              title: 'Subjects Count',
                              count: stats.totalSubjects.toString(),
                              icon: Icons.category_rounded,
                              colors: [Colors.orange.shade400, Colors.deepOrange.shade800],
                            ),
                            _buildStatCard(
                              context,
                              title: 'Lessons Count',
                              count: stats.totalLessons.toString(),
                              icon: Icons.library_books_rounded,
                              colors: [Colors.teal.shade400, Colors.teal.shade800],
                            ),
                            _buildStatCard(
                              context,
                              title: 'Quizzes Count',
                              count: stats.totalQuizzes.toString(),
                              icon: Icons.quiz_rounded,
                              colors: [Colors.purple.shade400, Colors.deepPurple.shade800],
                            ),
                            _buildStatCard(
                              context,
                              title: 'Video Views',
                              count: stats.totalVideoProgress.toString(),
                              icon: Icons.play_circle_fill_rounded,
                              colors: [Colors.blue.shade400, Colors.blue.shade800],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),

                        // --- Platform Activity (Charts) ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Platform Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          height: 250,
                          padding: const EdgeInsets.only(right: 16, top: 24, bottom: 8, left: 8),
                          decoration: BoxDecoration(
                             color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: _buildUserActivityChart(context, stats.quizActivity),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // --- Real-Time Feed ---
                        const LiveActivitySection(),
                      ],
                    );
                  },
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ShimmerGridLoader(itemCount: 4, childAspectRatio: 1.2),
                      const SizedBox(height: 32),
                      const ShimmerChartLoader(height: 250),
                    ],
                  ),
                  error: (err, stack) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning_rounded, color: theme.colorScheme.error, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load analytics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Actions Array
                Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickAction(context, 'Add Subject', Icons.add_circle, Colors.orange, () => context.push('/admin/add-subject')),
                      const SizedBox(width: 12),
                      _buildQuickAction(context, 'Add Lesson', Icons.play_lesson, Colors.teal, () => context.push('/admin/add-lesson')),
                      const SizedBox(width: 12),
                      _buildQuickAction(context, 'Add Quiz', Icons.quiz, Colors.purple, () => context.push('/admin/add-quiz')),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Management Database Edit Cards
                Text('Content Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                _buildManagementCard(
                  context: context,
                  title: 'Manage Subjects',
                  subtitle: 'Edit or delete existing subject categories.',
                  icon: Icons.category_rounded,
                  onTap: () => context.push('/admin/manage-subjects'),
                ),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context: context,
                  title: 'Manage Lessons',
                  subtitle: 'Update lesson videos and materials.',
                  icon: Icons.video_library_rounded,
                  onTap: () => context.push('/admin/manage-lessons'),
                ),
                const SizedBox(height: 12),
                _buildManagementCard(
                  context: context,
                  title: 'Manage Quizzes',
                  subtitle: 'Modify quiz questions and constraints.',
                  icon: Icons.rule_rounded,
                  onTap: () => context.push('/admin/manage-quizzes'),
                ),
                
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String count, required IconData icon, required List<Color> colors}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const Spacer(),
          // Title
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Counter
          AnimatedCounter(
            end: int.tryParse(count) ?? 0,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, color: color.shade700, size: 20),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildUserActivityChart(BuildContext context, List<int> quizActivity) {
    if (quizActivity.isEmpty || quizActivity.every((val) => val == 0)) {
       return const Center(child: Text('No activity yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
    }

    double maxVal = quizActivity.reduce((curr, next) => curr > next ? curr : next).toDouble();
    if (maxVal < 10) maxVal = 10;
    maxVal = maxVal * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if(value == maxVal) return const SizedBox.shrink();
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
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
                if (value % 2 == 0) {
                   return Text((value + 1).toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (quizActivity.length - 1 < 1) ? 1 : (quizActivity.length - 1).toDouble(),
        minY: 0,
        maxY: maxVal,
        lineBarsData: [
          LineChartBarData(
            spots: quizActivity.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
