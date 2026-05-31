import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/exercise_model.dart';

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  return ExercisesRepository();
});

class ExercisesRepository {
  final SupabaseClient _supabase;

  ExercisesRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  static const String _selectCols =
      'id, lesson_id, title_en, title_fr, title_ar, '
      'description_en, description_fr, description_ar, '
      'pdf_url, order_number, created_at';

  /// All exercises belonging to [lessonId], ordered by order_number.
  Future<List<ExerciseModel>> getExercisesByLesson(String lessonId) async {
    try {
      final data = await _supabase
          .from('exercises')
          .select(_selectCols)
          .eq('lesson_id', lessonId)
          .order('order_number', ascending: true);

      return (data as List)
          .map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Exercises] getExercisesByLesson failed: $e');
      throw Exception('Failed to fetch exercises: $e');
    }
  }

  /// Number of exercises per lesson for [lessonIds].
  /// Returns a map of lessonId → count (lessons with no exercises are omitted).
  Future<Map<String, int>> getExerciseCounts(List<String> lessonIds) async {
    if (lessonIds.isEmpty) return {};
    try {
      final data = await _supabase
          .from('exercises')
          .select('lesson_id')
          .inFilter('lesson_id', lessonIds);

      final counts = <String, int>{};
      for (final row in (data as List)) {
        final id = (row as Map)['lesson_id']?.toString();
        if (id == null) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('[Exercises] getExerciseCounts failed: $e');
      return {};
    }
  }
}
