import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';
import '../../../video_progress/domain/models/video_progress_model.dart';
import '../../../../core/widgets/shimmer_loaders.dart';
import '../../../../core/widgets/tap_scale_wrapper.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class ContinueLearningCard extends ConsumerStatefulWidget {
  const ContinueLearningCard({super.key});

  @override
  ConsumerState<ContinueLearningCard> createState() =>
      _ContinueLearningCardState();
}

class _ContinueLearningCardState extends ConsumerState<ContinueLearningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastWatchedAsync = ref.watch(lastWatchedProvider);
    final continueAsync = ref.watch(continueLearningProvider);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: lastWatchedAsync.when(
          data: (videoProgress) {
            if (videoProgress != null) {
              return _buildFromVideoProgress(context, ref, videoProgress);
            }
            return _buildFallback(context, continueAsync);
          },
          loading: () => _buildShimmer(),
          error: (_, __) => _buildFallback(context, continueAsync),
        ),
      ),
    );
  }

  Widget _buildFromVideoProgress(
    BuildContext context,
    WidgetRef ref,
    VideoProgressModel videoProgress,
  ) {
    final subjectsAsync = ref.watch(subjectsProvider);
    return subjectsAsync.when(
      data: (List<SubjectModel> subjects) {
        final subject = subjects.firstWhere(
          (s) => s.id == videoProgress.subjectId,
          orElse: () => SubjectModel(
            id: '',
            nameEn: 'Unknown',
            nameFr: 'Unknown',
            nameAr: 'Unknown',
            level: '',
            imageUrl: null,
            description: null,
          ),
        );
        final lessonsAsync =
            ref.watch(lessonsProvider(videoProgress.subjectId));
        return lessonsAsync.when(
          data: (paginatedState) {
            final lesson = paginatedState.lessons.firstWhere(
              (l) => l.id == videoProgress.lessonId,
              orElse: () => LessonModel(
                id: videoProgress.lessonId,
                subjectId: videoProgress.subjectId,
                titleEn: AppLocalizations.of(context)?.untitledLesson ?? 'Lesson',
                videoUrl: '',
                pdfUrl: '',
                orderNumber: 0,
              ),
            );
            return _buildCard(
              context,
              lesson: lesson,
              subjectName: subject.getName(Localizations.localeOf(context).languageCode),
              progress: videoProgress.progressFraction,
              positionSeconds: videoProgress.positionSeconds,
              durationSeconds: videoProgress.durationSeconds,
            );
          },
          loading: () => _buildShimmer(),
          error: (_, __) => _buildFallback(
            context,
            ref.watch(continueLearningProvider),
          ),
        );
      },
      loading: () => _buildShimmer(),
      error: (_, __) => _buildFallback(
        context,
        ref.watch(continueLearningProvider),
      ),
    );
  }

  Widget _buildFallback(
    BuildContext context,
    AsyncValue<LessonModel?> continueAsync,
  ) {
    return continueAsync.when(
      data: (lesson) {
        if (lesson == null) return const SizedBox.shrink();
        final loc = AppLocalizations.of(context)!;
        return _buildCard(
          context,
          lesson: lesson,
          subjectName: loc.upNext,
          progress: 0.0,
          positionSeconds: 0,
          durationSeconds: 0,
        );
      },
      loading: () => _buildShimmer(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildShimmer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ShimmerChartLoader(height: 140),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required LessonModel lesson,
    required String subjectName,
    required double progress,
    required double positionSeconds,
    required double durationSeconds,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📚 ${loc.continueLearning}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          TapScaleWrapper(
            onTap: () {
              context.push(
                '/subjects/${Uri.encodeComponent(lesson.subjectId)}/lessons/${lesson.id}/details',
                extra: {
                  'lesson': lesson,
                  'startPositionSeconds': positionSeconds,
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Play thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7C3AED),
                          Color(0xFF4A6CF7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subjectName,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (durationSeconds > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatDuration(durationSeconds),
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            else if (lesson.duration != null && lesson.duration! > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${lesson.duration} min',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.getTitle(Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                              value: value,
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              color: const Color(0xFF4A6CF7),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).round()}% ${loc.completeProgress}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (positionSeconds > 0 && durationSeconds > 0)
                              Text(
                                '${_formatDuration(positionSeconds)} / ${_formatDuration(durationSeconds)}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Continue button
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF4A6CF7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF4A6CF7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(double seconds) {
    final min = (seconds / 60).floor();
    final sec = (seconds % 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
