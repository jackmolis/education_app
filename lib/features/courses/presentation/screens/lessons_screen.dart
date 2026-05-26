import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/shimmer_loaders.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lesson_list_header.dart';
import '../providers/courses_provider.dart';
import '../../data/progress_repository.dart';
import '../../domain/models/subject_model.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/utils/localization_helper.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String levelName;
  final String subjectId;
  final SubjectModel? subject;

  const LessonsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    required this.subjectId,
    this.subject,
  });

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
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
    final locale = ref.watch(localeProvider);
    final loc = AppLocalizations.of(context)!;

    final String resolvedName = widget.subject != null ? widget.subject!.getName(locale.languageCode) : 'Lessons';

    return AppScaffold(
      // We manage our own SafeArea inside the header to allow it to touch the absolute screen edge seamlessly
      useSafeArea: false,
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonListHeader(
            subjectName: resolvedName,
            onBack: () {
              if (Navigator.canPop(context)) {
                context.pop();
              }
            },
          ),
          Expanded(
            child: lessonsAsync.when(
              data: (paginatedState) {
                final lessons = paginatedState.lessons;
                if (lessons.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.video_library_outlined,
                    title: loc.noLessonsYet,
                    subtitle: loc.lessonsAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () async {
                      ref.invalidate(lessonsProvider(widget.subjectId));
                      try {
                        await ref.read(lessonsProvider(widget.subjectId).future);
                      } catch (_) {}
                    },
                  );
                }
                
                // Supply the completed IDs directly into the list scope
                final completedLessonIds = completedLessonsAsync.maybeWhen(
                  data: (ids) => ids,
                  orElse: () => <String>{},
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    // Ignore unused_result to just refresh the provider mapping
                    return ref.refresh(lessonsProvider(widget.subjectId).future);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    itemCount: lessons.length + (paginatedState.isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == lessons.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final lesson = lessons[index];
                      final localizedTitle = lesson.getTitle(locale.languageCode);
                      
                      return LessonCard(
                        title: localizedTitle.isNotEmpty ? localizedTitle : loc.untitledLesson,
                        lessonId: lesson.id,
                        orderNumber: lesson.orderNumber,
                        durationMinutes: lesson.duration,
                        isCompleted: completedLessonIds.contains(lesson.id),
                        onTap: () {
                          context.push(
                            '/levels/${Uri.encodeComponent(widget.levelId)}/subjects/${Uri.encodeComponent(widget.subjectId)}/lessons/${lesson.id}',
                            extra: {
                              'levelName': widget.levelName,
                              'subject': widget.subject,
                              'startPositionSeconds': null,
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: ShimmerListLoader(itemCount: 5, itemHeight: 100),
              ),
              error: (error, _) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadLessons,
                      actionLabel: loc.tryAgain,
                      onAction: () async {
                        ref.invalidate(lessonsProvider(widget.subjectId));
                        try {
                          await ref.read(lessonsProvider(widget.subjectId).future);
                        } catch (_) {}
                      },
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
}
