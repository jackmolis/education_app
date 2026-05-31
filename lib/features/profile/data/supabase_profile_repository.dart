import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile_repository.dart';
import '../domain/models/user_profile_model.dart';
import '../domain/models/quiz_result_model.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _supabaseClient;

  SupabaseProfileRepository(this._supabaseClient);

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  @override
  Future<List<QuizResultModel>> getUserQuizResults(String userId) async {
    try {
      final response = await _supabaseClient
          .from('results')
          .select(
            'id, user_id, lesson_id, score, total, created_at, lessons(title_en, title_fr, title_ar)',
          )
          .eq('user_id', userId);

      return (response as List<dynamic>)
          .map((item) => QuizResultModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user quiz results: $e');
    }
  }
}
