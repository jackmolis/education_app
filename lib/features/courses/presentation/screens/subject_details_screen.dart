import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/shimmer_loaders.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/courses_provider.dart';
import '../../data/progress_repository.dart';
import '../../../courses/domain/models/lesson_model.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class SubjectDetailsScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectDetailsScreen({
    super.key,
    required this.subjectId,
    this.subjectName = 'Subject Details',
  });

  @override
  ConsumerState<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends ConsumerState<SubjectDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(lessonsProvider(widget.subjectId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider(widget.subjectId));
    final completedLessonsAsync = ref.watch(completedLessonIdsProvider);
    final subjectAsync = ref.watch(subjectByIdProvider(widget.subjectId));

    final resolvedName = subjectAsync.maybeWhen(
      data: (subject) =>
          subject?.getName(Localizations.localeOf(context).languageCode) ??
          widget.subjectName,
      orElse: () => widget.subjectName,
    );

    return AppScaffold(
      useSafeArea: false,
      backgroundColor: const Color(0xFFF8F9FD),
      body: lessonsAsync.when(
        data: (paginatedState) {
          final lessons = paginatedState.lessons;
          final completedLessonIds = completedLessonsAsync.maybeWhen(
            data: (ids) => ids,
            orElse: () => <String>{},
          );

          final totalLessons = lessons.length;
          int completedCount = 0;
          LessonModel? nextLesson;

          for (var i = 0; i < lessons.length; i++) {
            final lesson = lessons[i];
            if (completedLessonIds.contains(lesson.id)) {
              completedCount++;
            } else if (nextLesson == null) {
              nextLesson = lesson;
            }
          }

          final progress = totalLessons == 0 ? 0.0 : (completedCount / totalLessons).clamp(0.0, 1.0);

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context, resolvedName, totalLessons, completedCount, progress),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      if (nextLesson != null || lessons.isNotEmpty)
                        _buildContinueLearningCard(context, nextLesson ?? lessons.last),
                      const SizedBox(height: 32),
                      const Text(
                        'COURSE CONTENT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (lessons.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: 'No Lessons Yet',
                    subtitle: 'Lessons for this subject will appear here soon.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == lessons.length) {
                        return paginatedState.isFetchingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }

                      final lesson = lessons[index];
                      final isCompleted = completedLessonIds.contains(lesson.id);
                      final isLocked = !isCompleted && nextLesson != null && lesson.id != nextLesson.id && lesson.orderNumber > nextLesson.orderNumber;
                      final isInProgress = nextLesson?.id == lesson.id;

                      return _ModernLessonCard(
                        lesson: lesson,
                        isCompleted: isCompleted,
                        isLocked: isLocked,
                        isInProgress: isInProgress,
                        onTap: isLocked
                            ? null
                            : () => context.push(
                                  '/subjects/${Uri.encodeComponent(widget.subjectId)}/lessons/${lesson.id}',
                                  extra: lesson,
                                ),
                      );
                    },
                    childCount: lessons.length + (paginatedState.isFetchingMore ? 1 : 0),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: ShimmerListLoader(itemCount: 5, itemHeight: 120),
          ),
        ),
        error: (error, _) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Error loading lessons',
                actionLabel: 'Retry',
                onAction: () {
                  ref.invalidate(lessonsProvider(widget.subjectId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, int total, int completed, double progress) {
    return SliverAppBar(
      expandedHeight: 260.0,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF3B82F6),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FlexibleSpaceBar(
          background: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'COURSE OVERVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completed / $total Lessons',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () {
          if (Navigator.canPop(context)) {
            context.pop();
          }
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: const [
        Expanded(child: _StatItem(icon: Icons.access_time_filled, value: '12h 30m', label: 'Learned', color: Colors.orange)),
        SizedBox(width: 12),
        Expanded(child: _StatItem(icon: Icons.quiz_rounded, value: '4', label: 'Quizzes', color: Colors.purple)),
        SizedBox(width: 12),
        Expanded(child: _StatItem(icon: Icons.local_fire_department_rounded, value: '5 Days', label: 'Streak', color: Colors.redAccent)),
      ],
    );
  }

  Widget _buildContinueLearningCard(BuildContext context, LessonModel lesson) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle_fill, color: Color(0xFF4A6CF7), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lesson.getTitle(Localizations.localeOf(context).languageCode),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.45, 
              minHeight: 6,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(Color(0xFF4A6CF7)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(
                '/subjects/${Uri.encodeComponent(widget.subjectId)}/lessons/${lesson.id}',
                extra: lesson,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
               child: const Text('Resume Lesson', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernLessonCard extends StatelessWidget {
  final LessonModel lesson;
  final bool isCompleted;
  final bool isLocked;
  final bool isInProgress;
  final VoidCallback? onTap;

  const _ModernLessonCard({
    required this.lesson,
    required this.isCompleted,
    required this.isLocked,
    required this.isInProgress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isCompleted 
        ? Colors.green 
        : isInProgress 
            ? const Color(0xFF4A6CF7) 
            : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.03),
             blurRadius: 10,
             offset: const Offset(0, 4),
          ),
        ],
        border: isLocked ? null : Border.all(
          color: isInProgress ? const Color(0xFF4A6CF7).withValues(alpha: 0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFFF1F5F9) : themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.green, size: 24)
                        : isLocked
                            ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 20)
                            : Text(
                                '${lesson.orderNumber}',
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                ExpectedContent(lesson: lesson, isLocked: isLocked, isInProgress: isInProgress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpectedContent extends StatelessWidget {
  final LessonModel lesson;
  final bool isLocked;
  final bool isInProgress;

  const ExpectedContent({super.key, required this.lesson, required this.isLocked, required this.isInProgress});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.getTitle(Localizations.localeOf(context).languageCode),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
                Icon(
                  Icons.play_circle_outline, 
                  size: 14, 
                  color: isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${lesson.duration ?? 10} mins', 
                  style: TextStyle(
                    fontSize: 13,
                    color: isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isInProgress) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6CF7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('In Progress', style: TextStyle(color: Color(0xFF4A6CF7), fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ]
            ],
          ),
          if (isInProgress)...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                  value: 0.45,
                  minHeight: 4,
                  backgroundColor: Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation(Color(0xFF4A6CF7)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
