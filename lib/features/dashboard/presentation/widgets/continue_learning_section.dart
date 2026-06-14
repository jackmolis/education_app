import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';
import '../../../video_progress/domain/models/video_progress_model.dart';
import '../../../../core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class ContinueLearningSection extends ConsumerWidget {
  const ContinueLearningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastWatchedAsync = ref.watch(lastWatchedProvider);
    final continueAsync = ref.watch(continueLearningProvider);

    return lastWatchedAsync.when(
      data: (videoProgress) {
        if (videoProgress != null) {
          final subjectAsync = ref.watch(subjectByIdProvider(videoProgress.subjectId));
          return subjectAsync.when(
            data: (subject) {
              final resolvedSubject = subject ?? SubjectModel(
                id: '',
                nameEn: 'Unknown',
                nameFr: 'Unknown',
                nameAr: 'Unknown',
                level: '',
                imageUrl: null,
                description: null,
              );
              final lessonsAsync = ref.watch(lessonsProvider(videoProgress.subjectId));
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
                  return _buildLastWatchedCard(context, videoProgress, lesson, resolvedSubject.getName(Localizations.localeOf(context).languageCode));
                },
                loading: () => _buildShimmer(),
                error: (error, stack) => _buildFallback(continueAsync),
              );
            },
            loading: () => _buildShimmer(),
            error: (error, stack) => _buildFallback(continueAsync),
          );
        }
        return _buildFallback(continueAsync);
      },
      loading: () => _buildShimmer(),
      error: (error, stack) => _buildFallback(continueAsync),
    );
  }

  Widget _buildShimmer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: ShimmerChartLoader(height: 160),
    );
  }

  Widget _buildFallback(AsyncValue<LessonModel?> continueAsync) {
    return continueAsync.when(
      data: (lesson) {
        if (lesson == null) return const SizedBox.shrink();
        return _buildUpNextCard(lesson);
      },
      loading: () => _buildShimmer(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildLastWatchedCard(
    BuildContext context,
    VideoProgressModel videoProgress,
    LessonModel lesson,
    String subjectName,
  ) {
    final progress = videoProgress.progressFraction;
    final posMin = (videoProgress.positionSeconds / 60).floor();
    final posSec = (videoProgress.positionSeconds % 60).round();
    final durMin = (videoProgress.durationSeconds / 60).floor();
    final durSec = (videoProgress.durationSeconds % 60).round();

    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.continueWatching,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              context.push(
                '/subjects/${Uri.encodeComponent(lesson.subjectId)}/lessons/${lesson.id}/details',
                extra: {
                  'lesson': lesson,
                  'startPositionSeconds': videoProgress.positionSeconds,
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4A6CF7), Color(0xFFFF8A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6CF7).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Play button thumbnail
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.getTitle(Localizations.localeOf(context).languageCode),
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, _) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            if (videoProgress.durationSeconds > 0)
                              Text(
                                '$posMin:${posSec.toString().padLeft(2, '0')} / $durMin:${durSec.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                              ),
                          ],
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
    );
  }

  Widget _buildUpNextCard(LessonModel lesson) {
    return Builder(builder: (context) {
      final loc = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.continueLearning,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                context.push(
                  '/subjects/${Uri.encodeComponent(lesson.subjectId)}/lessons/${lesson.id}/details',
                  extra: {
                    'lesson': lesson,
                    'startPositionSeconds': 0.0,
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4A6CF7), Color(0xFFFF8A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A6CF7).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.upNext,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lesson.getTitle(Localizations.localeOf(context).languageCode),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
