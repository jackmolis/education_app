import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/quiz_model.dart';

class QuizRepository {
  final SupabaseClient _supabase;

  QuizRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<List<QuizModel>> getQuizByLessonId(String lessonId) async {
    try {
      debugPrint('Fetching quiz questions for lesson: $lessonId');
      final data = await _supabase
          .from('quizzes')
          .select()
          .eq('lesson_id', lessonId);

      debugPrint('Quiz questions fetched successfully: ${data.length} items');
      return (data as List).map((json) => QuizModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching quiz: $e');
      throw Exception('Failed to fetch quiz: $e');
    }
  }

  Future<void> saveQuizResult({
    required String lessonId,
    required int score,
    required int total,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Cannot save quiz: No authenticated user');
        return;
      }

      await _supabase.from('results').insert({
        'user_id': userId,
        'lesson_id': lessonId,
        'score': score,
        'total': total,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('Quiz result saved successfully');
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
      throw Exception('Failed to save quiz result: $e');
    }
  }
}
