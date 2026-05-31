import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/shimmer_loaders.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../domain/models/exercise_model.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/exercises_provider.dart';
import '../providers/storage_provider.dart';

/// Exercise list for a single lesson.
/// Level → Subject → Sections → SolvedExercises → LessonExercisesScreen
class LessonExercisesScreen extends ConsumerWidget {
  final String lessonId;
  final String lessonTitle;

  const LessonExercisesScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeProvider).languageCode;
    final exercisesAsync = ref.watch(lessonExercisesProvider(lessonId));

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
                        lessonTitle.isNotEmpty ? lessonTitle : loc.untitledLesson,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
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
            child: exercisesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: ShimmerListLoader(itemCount: 5, itemHeight: 110),
              ),
              error: (e, _) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadExercises,
                      actionLabel: loc.tryAgain,
                      onAction: () =>
                          ref.invalidate(lessonExercisesProvider(lessonId)),
                    ),
                  ),
                ],
              ),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: loc.noExercisesYet,
                    subtitle: loc.exercisesAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () =>
                        ref.invalidate(lessonExercisesProvider(lessonId)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(lessonExercisesProvider(lessonId));
                    await ref.read(lessonExercisesProvider(lessonId).future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return _ExerciseCard(
                        index: index,
                        title: exercise.getTitle(localeCode),
                        description: exercise.getDescription(localeCode),
                        hasPdf: exercise.hasPdf,
                        onOpenPdf: exercise.hasPdf
                            ? () => _openPdf(context, ref, exercise, localeCode)
                            : null,
                        openPdfLabel: loc.openPdf,
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

  Future<void> _openPdf(
    BuildContext context,
    WidgetRef ref,
    ExerciseModel exercise,
    String localeCode,
  ) async {
    final title = exercise.getTitle(localeCode);
    final router = GoRouter.of(context);
    try {
      // Await the signed URL (handles the still-loading case robustly).
      final signedUrl =
          await ref.read(lessonMediaUrlProvider(exercise.pdfUrl).future);
      if (signedUrl.isEmpty) return;
      router.push(
        '/pdf-viewer',
        extra: {
          'pdfUrl': signedUrl,
          'title': title,
          'lessonId': 'exercise_${exercise.id}',
        },
      );
    } catch (_) {
      // Silently ignore — the card stays interactive for a retry.
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final bool hasPdf;
  final VoidCallback? onOpenPdf;
  final String openPdfLabel;

  const _ExerciseCard({
    required this.index,
    required this.title,
    required this.description,
    required this.hasPdf,
    required this.onOpenPdf,
    required this.openPdfLabel,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF10B981);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            if (hasPdf) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFF97316), size: 20),
                  label: Text(
                    openPdfLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
