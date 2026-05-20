import 'package:supabase_flutter/supabase_flutter.dart';

class NotesRepository {
  final SupabaseClient _supabase;

  NotesRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch the user's note for a specific lesson (null if none).
  Future<String?> getNote({
    required String userId,
    required String lessonId,
  }) async {
    final data = await _supabase
        .from('notes')
        .select('content')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (data == null) return null;
    return data['content'] as String?;
  }

  /// Upsert (insert or update) the user's note for a lesson.
  Future<void> saveNote({
    required String userId,
    required String lessonId,
    required String content,
  }) async {
    await _supabase.from('notes').upsert(
      {
        'user_id': userId,
        'lesson_id': lessonId,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,lesson_id',
    );
  }
}
