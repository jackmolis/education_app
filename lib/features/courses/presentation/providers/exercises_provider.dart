import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exercise_model.dart';
import '../../domain/models/lesson_model.dart';
import '../../data/exercises_repository.dart';
import 'courses_provider.dart';

/// All lessons of a subject (non-paginated) for the Solved Exercises lesson list.
/// Reuses the existing CoursesRepository.getLessons with a large page size so
/// the user sees every lesson at once.
final subjectLessonsForExercisesProvider =
    FutureProvider.family<List<LessonModel>, String>((ref, subjectId) async {
  final repo = ref.watch(coursesRepositoryProvider);
  return repo.getLessons(subjectId, limit: 1000, offset: 0);
});

/// Map of lessonId → exercise count for a given list of lessons.
/// Keyed by subjectId; reads the already-loaded lessons to know which ids to count.
final exerciseCountsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, subjectId) async {
  final lessons =
      await ref.watch(subjectLessonsForExercisesProvider(subjectId).future);
  final ids = lessons.map((l) => l.id).toList();
  final repo = ref.watch(exercisesRepositoryProvider);
  return repo.getExerciseCounts(ids);
});

/// Exercises belonging to a single lesson.
final lessonExercisesProvider =
    FutureProvider.family<List<ExerciseModel>, String>((ref, lessonId) async {
  final repo = ref.watch(exercisesRepositoryProvider);
  return repo.getExercisesByLesson(lessonId);
});
