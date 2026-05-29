import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subject_model.dart';
import '../../domain/models/lesson_model.dart';
import '../../data/courses_repository.dart';
import '../../data/progress_repository.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository();
});

final subjectsProvider = FutureProvider<List<SubjectModel>>((ref) async {
  final repository = ref.watch(coursesRepositoryProvider);
  return repository.getSubjects();
});

class PaginatedLessonsState {
  final List<LessonModel> lessons;
  final bool hasMore;
  final bool isFetchingMore;

  PaginatedLessonsState({
    required this.lessons,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  PaginatedLessonsState copyWith({
    List<LessonModel>? lessons,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return PaginatedLessonsState(
      lessons: lessons ?? this.lessons,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class PaginatedLessonsNotifier extends FamilyAsyncNotifier<PaginatedLessonsState, String> {
  static const int _limit = 10;
  
  @override
  Future<PaginatedLessonsState> build(String arg) async {
    final repository = ref.watch(coursesRepositoryProvider);
    final initialLessons = await repository.getLessons(arg, limit: _limit, offset: 0);
    return PaginatedLessonsState(
      lessons: initialLessons,
      hasMore: initialLessons.length == _limit,
    );
  }

  Future<void> loadMore() async {
    final currentVal = state.valueOrNull;
    if (currentVal == null || !currentVal.hasMore || currentVal.isFetchingMore) {
      return;
    }

    // Instead of completely wiping the AsyncData state with AsyncValue.loading(),
    // we use our robust flag to keep the UI intact while fetching.
    state = AsyncValue.data(currentVal.copyWith(isFetchingMore: true));
    
    try {
      final repository = ref.read(coursesRepositoryProvider);
      final offset = currentVal.lessons.length;
      final newLessons = await repository.getLessons(arg, limit: _limit, offset: offset);
      
      state = AsyncValue.data(
        currentVal.copyWith(
          lessons: [...currentVal.lessons, ...newLessons],
          hasMore: newLessons.length == _limit,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      // Revert loading state on error, ensuring we still have the previous data.
      // We set hasMore to false specifically to prevent infinite layout-scroll loops
      // (like 416 Range Not Satisfiable loops) from DDOSing the server.
      state = AsyncValue.data(currentVal.copyWith(
        isFetchingMore: false,
        hasMore: false,
      ));
    }
  }
}

final lessonsProvider = AsyncNotifierProviderFamily<PaginatedLessonsNotifier, PaginatedLessonsState, String>(() {
  return PaginatedLessonsNotifier();
});

final recentLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  // Optimized: fetch lessons ONLY from the last-watched subject (1 query)
  // instead of iterating all subjects (which caused N+1 queries).
  final repo = ref.read(coursesRepositoryProvider);
  try {
    final lastWatched = await ref.watch(lastWatchedProvider.future);
    if (lastWatched == null) return [];
    final lessons = await repo.getLessons(lastWatched.subjectId, limit: 5, offset: 0);
    return lessons;
  } catch (_) {
    return [];
  }
});

final continueLearningProvider = FutureProvider<LessonModel?>((ref) async {
  // Optimized: use lastWatchedProvider (single DB query) to find the subject,
  // then fetch only that subject's lessons to find the next incomplete one.
  final lastWatched = await ref.watch(lastWatchedProvider.future);
  if (lastWatched == null) return null;

  try {
    final repo = ref.read(coursesRepositoryProvider);
    final lessonsState = await ref.watch(lessonsProvider(lastWatched.subjectId).future);
    final completedLessonIds = await ref.watch(completedLessonIdsProvider.future);

    for (final lesson in lessonsState.lessons) {
      if (!completedLessonIds.contains(lesson.id)) {
        return lesson;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
});
