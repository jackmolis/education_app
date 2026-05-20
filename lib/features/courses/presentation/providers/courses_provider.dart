import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subject_model.dart';
import '../../domain/models/lesson_model.dart';
import '../../data/courses_repository.dart';
import '../../data/progress_repository.dart';

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

final recentLessonsProvider = FutureProvider.autoDispose<List<LessonModel>>((ref) async {
  final subjects = await ref.watch(subjectsProvider.future);
  final List<LessonModel> allLessons = [];
  
  // Fetch lessons for all subjects
  for (final subject in subjects) {
    try {
      final lessonsState = await ref.watch(lessonsProvider(subject.id).future);
      allLessons.addAll(lessonsState.lessons);
    } catch (e) {
      // Skip if a subject fails to load its lessons
      continue;
    }
  }
  
  // Sort or slice them (for now, simply take the newest/last ones if ordered ascending)
  if (allLessons.length > 5) {
    return allLessons.sublist(0, 5);
  }
  return allLessons;
});

final continueLearningProvider = FutureProvider.autoDispose<LessonModel?>((ref) async {
  final subjects = await ref.watch(subjectsProvider.future);
  final completedLessonIds = await ref.watch(completedLessonIdsProvider.future);
  
  // Iterate subjects and their lessons in order
  for (final subject in subjects) {
    try {
      final lessonsState = await ref.watch(lessonsProvider(subject.id).future);
      
      // Find the first lesson that is NOT in the completed list
      for (final lesson in lessonsState.lessons) {
        if (!completedLessonIds.contains(lesson.id)) {
          return lesson;
        }
      }
    } catch (e) {
      continue; // Skip failed fetches
    }
  }
  
  // Return null if all lessons across all subjects are completed, or no lessons exist
  return null;
});
