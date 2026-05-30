import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/lesson_video_section.dart';
import '../widgets/lesson_progress_bar.dart';
import '../widgets/lesson_info_section.dart';
import '../widgets/lesson_actions_row.dart';
import '../widgets/lesson_tabs_section.dart';
import '../widgets/quiz_cta.dart';
import '../../domain/models/lesson_model.dart';
import '../providers/storage_provider.dart';
import '../../data/progress_repository.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';
import '../../../video_progress/domain/models/video_progress_model.dart';
import '../providers/lesson_details_provider.dart';
import '../../../notes/presentation/notes_screen.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class LessonDetailsScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String levelName;
  final String subjectId;
  final String lessonId;
  final double? startPositionSeconds;

  const LessonDetailsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.subjectId,
    required this.lessonId,
    this.startPositionSeconds,
  });

  @override
  ConsumerState<LessonDetailsScreen> createState() =>
      _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends ConsumerState<LessonDetailsScreen> {
  bool _isMarkingAsComplete = false;
  final GlobalKey<LessonVideoSectionState> _videoSectionKey = GlobalKey();

  /// Saves progress then pops.
  Future<void> _saveAndPop() async {
    try {
      await _videoSectionKey.currentState?.saveCurrentProgress();
    } catch (e) {
      debugPrint('[VideoProgress] _saveAndPop error: $e');
    }
    // Invalidate on exit so other screens show updated progress
    ref.invalidate(lessonVideoProgressProvider(widget.lessonId));
    ref.invalidate(lastWatchedProvider);
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailsProvider(widget.lessonId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return lessonAsync.when(
      data: (data) => _buildScreen(context, data, isDark),
      loading: () => const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Back button so user can leave
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                      size: 22,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 52, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)?.failedToLoadLesson ?? 'Failed to load lesson',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString().replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => ref
                              .invalidate(lessonDetailsProvider(widget.lessonId)),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6CF7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Subject name localization ─────────────────────────────────────

  /// Resolves the subject name for the current [languageCode] from the joined
  /// `subjects` row, with graceful fallbacks. Per-language order:
  ///   ar -> name_ar -> name -> 'Unknown'
  ///   fr -> name_fr -> name -> 'Unknown'
  ///   en -> name_en -> name -> 'Unknown'
  String _resolveSubjectName(
    Map<String, dynamic>? subjectJson,
    String languageCode,
  ) {
    if (subjectJson == null) return 'Unknown';

    String? pick(String key) {
      final value = subjectJson[key]?.toString();
      return (value != null && value.isNotEmpty) ? value : null;
    }

    final String? localized = switch (languageCode) {
      'ar' => pick('name_ar'),
      'fr' => pick('name_fr'),
      _ => pick('name_en'),
    };

    return localized ?? pick('name') ?? 'Unknown';
  }

  Widget _buildScreen(
    BuildContext context,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    final lesson = LessonModel.fromJson(data);

    // Language-aware subject name. Mirrors the same locale source used for
    // lesson.getTitle(...) below. The joined `subjects` row exposes the
    // localized columns (name_ar / name_fr / name_en); fall back to the
    // default `name` column, then to 'Unknown'.
    final subjectJson = data['subjects'] as Map<String, dynamic>?;
    final subjectName = _resolveSubjectName(
      subjectJson,
      Localizations.localeOf(context).languageCode,
    );

    final completedLessonsAsync = ref.watch(completedLessonIdsProvider);
    final isCompleted = completedLessonsAsync.maybeWhen(
      data: (ids) => ids.contains(lesson.id),
      orElse: () => false,
    );

    final savedProgressAsync =
        ref.watch(lessonVideoProgressProvider(lesson.id));
    final nextLessonKey = '${lesson.subjectId}|${lesson.orderNumber}';
    final nextLessonAsync = ref.watch(nextLessonProvider(nextLessonKey));

    final VideoProgressModel? savedProgress = savedProgressAsync.value;
    final double currentPosition = savedProgress?.positionSeconds ?? 0.0;
    final double totalDuration =
        savedProgress?.durationSeconds ?? (lesson.duration?.toDouble() ?? 1.0);
    final double progressPercentage =
        totalDuration > 0 ? (currentPosition / totalDuration) : 0.0;

    // Initial resume position: navigation param takes priority, else saved DB value.
    final double initialPosition =
        widget.startPositionSeconds ?? currentPosition;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndPop();
      },
      child: AppScaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            // Back button bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                        size: 22,
                      ),
                      onPressed: _saveAndPop,
                    ),
                    const Spacer(),
                    // Next lesson chip
                    nextLessonAsync.when(
                      data: (next) {
                        if (next == null) return const SizedBox.shrink();
                        return TextButton.icon(
                          onPressed: () {
                            context.push(
                              '/levels/${Uri.encodeComponent(widget.levelId)}/subjects/${Uri.encodeComponent(lesson.subjectId)}/lessons/${next.id}/details',
                              extra: {
                                'levelName': widget.levelName,
                              },
                            );
                          },
                          icon: Text(
                            AppLocalizations.of(context)?.next ?? 'Next',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          label: const Icon(Icons.skip_next_rounded, size: 20),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Video Player — isolated widget. Watches ONLY the
                    //    signed-URL provider, so progress/completion/next-lesson
                    //    updates never rebuild or recreate the player.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RepaintBoundary(
                        child: LessonVideoSection(
                          key: _videoSectionKey,
                          lesson: lesson,
                          initialPositionSeconds: initialPosition,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Progress Bar
                    if (lesson.videoUrl.isNotEmpty) ...[
                      LessonProgressBar(progress: progressPercentage),
                      const SizedBox(height: 20),
                    ],

                    // 3. Lesson Info
                    LessonInfoSection(
                      title: lesson.getTitle(Localizations.localeOf(context).languageCode),
                      subjectName: subjectName,
                      durationMinutes: lesson.duration,
                      orderNumber: lesson.orderNumber,
                    ),
                    const SizedBox(height: 20),

                    // 4. Actions Row
                    _buildActionsRow(context, lesson, isCompleted),
                    const SizedBox(height: 24),

                    // 5. Tabs Section
                    _buildTabsSection(context, lesson),
                    const SizedBox(height: 24),

                    // 6. Quiz CTA
                    QuizCta(
                      onStartQuiz: () => context.push(
                            '/levels/${Uri.encodeComponent(widget.levelId)}/subjects/${Uri.encodeComponent(lesson.subjectId)}/lessons/${lesson.id}/quiz',
                          ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions Row Builder ───────────────────────────────────────────

  Widget _buildActionsRow(
    BuildContext context,
    LessonModel lesson,
    bool isCompleted,
  ) {
    return LessonActionsRow(
      hasPdf: lesson.pdfUrl.isNotEmpty,
      isCompleted: isCompleted,
      isMarkingComplete: _isMarkingAsComplete,
      onOpenPdf: lesson.pdfUrl.isNotEmpty
          ? () => _openPdf(context, lesson)
          : null,
      onMarkComplete: () => _markComplete(lesson),
      onNotes: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NotesScreen(
              lessonId: lesson.id,
              lessonTitle: lesson.getTitle(Localizations.localeOf(context).languageCode),
            ),
          ),
        );
      },
    );
  }

  // ── Tabs Section Builder ──────────────────────────────────────────

  Widget _buildTabsSection(BuildContext context, LessonModel lesson) {
    return LessonTabsSection(
      lessonId: lesson.id,
      description: lesson.getDescription(Localizations.localeOf(context).languageCode),
      content: lesson.content,
      hasPdf: lesson.pdfUrl.isNotEmpty,
      onOpenPdf: lesson.pdfUrl.isNotEmpty
          ? () => _openPdf(context, lesson)
          : null,
    );
  }

  // ── Business Actions ──────────────────────────────────────────────

  void _openPdf(BuildContext context, LessonModel lesson) {
    final pdfUrlAsync =
        ref.read(lessonMediaUrlProvider(lesson.pdfUrl));
    pdfUrlAsync.whenData((signedPdfUrl) {
      context.push(
        '/pdf-viewer',
        extra: {
          'pdfUrl': signedPdfUrl,
          'title': lesson.getTitle(Localizations.localeOf(context).languageCode),
          'lessonId': lesson.id,
        },
      );
    });
  }

  Future<void> _markComplete(LessonModel lesson) async {
    setState(() => _isMarkingAsComplete = true);
    try {
      final repo = ref.read(progressRepositoryProvider);
      final auth = ref.read(authRepositoryProvider);
      final user = auth.currentUser;

      if (user != null) {
        await repo.markLessonAsCompleted(
          user.id,
          lesson.id,
          lesson.subjectId,
        );
        ref.invalidate(completedLessonIdsProvider);
        ref.invalidate(subjectProgressProvider);
        ref.invalidate(totalCompletedLessonsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson marked as completed!'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAsComplete = false);
    }
  }
}
