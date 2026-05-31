import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/core/widgets/tap_scale_wrapper.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../domain/models/subject_model.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/exercises_provider.dart';

/// Solved Exercises → lesson list for a subject.
/// Level → Subject → Sections → SolvedExercisesScreen → LessonExercisesScreen
class SolvedExercisesScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;
  final String subjectId;
  final SubjectModel? subject;

  const SolvedExercisesScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.subjectId,
    this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final lessonsAsync = ref.watch(subjectLessonsForExercisesProvider(subjectId));
    final countsAsync = ref.watch(exerciseCountsProvider(subjectId));

    final subjectName =
        subject != null ? subject!.getName(localeCode) : loc.sectionSolvedExercises;

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.sectionSolvedExercises,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: lessonsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: ShimmerListLoader(itemCount: 6, itemHeight: 84),
              ),
              error: (e, _) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadLessons,
                      actionLabel: loc.tryAgain,
                      onAction: () => ref.invalidate(
                          subjectLessonsForExercisesProvider(subjectId)),
                    ),
                  ),
                ],
              ),
              data: (lessons) {
                if (lessons.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: loc.noLessonsYet,
                    subtitle: loc.lessonsAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () => ref.invalidate(
                        subjectLessonsForExercisesProvider(subjectId)),
                  );
                }

                final counts = countsAsync.valueOrNull ?? const {};

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(subjectLessonsForExercisesProvider(subjectId));
                    ref.invalidate(exerciseCountsProvider(subjectId));
                    await ref
                        .read(subjectLessonsForExercisesProvider(subjectId).future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final title = lesson.getTitle(localeCode);
                      final count = counts[lesson.id] ?? 0;

                      return _LessonExerciseCard(
                        index: index,
                        title: title.isNotEmpty ? title : loc.untitledLesson,
                        orderNumber: lesson.orderNumber,
                        exerciseCount: count,
                        countLabel: loc.exercisesCount(count),
                        onTap: () {
                          context.push(
                            '/levels/${Uri.encodeComponent(levelId)}/subjects/${Uri.encodeComponent(subjectId)}/exercises/${Uri.encodeComponent(lesson.id)}',
                            extra: {'lessonTitle': title},
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonExerciseCard extends StatelessWidget {
  final int index;
  final String title;
  final int orderNumber;
  final int exerciseCount;
  final String countLabel;
  final VoidCallback onTap;

  const _LessonExerciseCard({
    required this.index,
    required this.title,
    required this.orderNumber,
    required this.exerciseCount,
    required this.countLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF10B981);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TapScaleWrapper(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.checklist_rtl_rounded,
                      color: accent, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          countLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[300], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
