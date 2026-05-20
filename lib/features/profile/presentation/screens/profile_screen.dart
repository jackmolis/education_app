import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/profile_providers.dart';
import '../providers/profile_analytics_provider.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../../courses/data/progress_repository.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_stat_card.dart';
import '../widgets/quiz_result_list_tile.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final quizResultsAsync = ref.watch(userQuizResultsProvider);
    final globalProgressAsync = ref.watch(globalProgressProvider);
    final analytics = ref.watch(profileAnalyticsProvider);

    return AppScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('User profile not found.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(userQuizResultsProvider);
              ref.invalidate(totalCompletedLessonsProvider);
              ref.invalidate(totalSystemLessonsProvider);
              ref.invalidate(globalProgressProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // --- Custom Header Section ---
                   Padding(
                     padding: const EdgeInsets.only(bottom: 24.0, top: 4.0),
                     child: Row(
                       children: [
                         const SizedBox(width: 48), // Balance for trailing IconButton
                         const Expanded(
                           child: Text(
                             'Analytics Dashboard',
                             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                             textAlign: TextAlign.center,
                           ),
                         ),
                         IconButton(
                           icon: const Icon(Icons.logout),
                           onPressed: () async {
                             final authRepo = ref.read(authRepositoryProvider);
                             await authRepo.signOut();
                           },
                           tooltip: 'Logout',
                         ),
                       ],
                     ),
                   ),
                   // --- Profile Summary ---
                  Row(
                    children: [
                      ProfileAvatar(name: profile.name, radius: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              profile.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Level: ${profile.level}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (profile.role == 'teacher') ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/admin'),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Admin Panel'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // --- Progress Section ---
                  Text(
                    'Course Progression',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: globalProgressAsync.when(
                      data: (progress) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Overall Completion', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => const Text('Could not load course progress'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Statistics Cards Group ---
                  quizResultsAsync.when(
                    data: (results) {
                      final totalQuizzes = results.length;
                      return Row(
                        children: [
                          Expanded(
                            child: ProfileStatCard(
                              title: 'Quizzes Taken',
                              value: totalQuizzes.toString(),
                              icon: Icons.assignment_turned_in,
                              gradientColors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ProfileStatCard(
                              title: 'Average Score',
                              value: '${analytics.averageScore.toStringAsFixed(1)}%',
                              icon: Icons.query_stats,
                              gradientColors: const [Color(0xFFF12711), Color(0xFFF5AF19)],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),

                  const SizedBox(height: 24),

                  // --- Insights Section ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getInsightColor(analytics.averageScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getInsightColor(analytics.averageScore).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getInsightIcon(analytics.averageScore), color: _getInsightColor(analytics.averageScore), size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Performance Insight',
                                style: TextStyle(
                                  color: _getInsightColor(analytics.averageScore),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                analytics.insightMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Chart Section ---
                  Text(
                    'Score Progression',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (analytics.scoreHistory.length < 2)
                     Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: const Center(
                        child: Text('Complete more quizzes to see your progression chart.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      padding: const EdgeInsets.only(right: 16, top: 24, bottom: 8, left: 8),
                      decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20,
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
                                  return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey));
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
                                  if (value % 1 == 0) {
                                     return Text('#${(value + 1).toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (analytics.scoreHistory.length - 1).toDouble(),
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: analytics.scoreHistory.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
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
                      ),
                    ),

                  const SizedBox(height: 32),

                  // --- Recent Activity ---
                  Text(
                    'Recent Quiz Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  quizResultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) return const Center(child: Text('No recent activity.'));
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          // The quiz result row can just reuse the existing widget
                          return QuizResultListTile(result: results[index]);
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getInsightColor(double score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getInsightIcon(double score) {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 50) return Icons.trending_up;
    return Icons.warning;
  }
}
