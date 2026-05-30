import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/courses_repository.dart';
import '../../domain/models/lesson_model.dart';
import 'courses_provider.dart';

/// Next lesson in the same subject (by order). Key: `"$subjectId|$orderNumber"`.
final nextLessonProvider = FutureProvider.autoDispose.family<LessonModel?, String>((ref, compositeKey) async {
  final parts = compositeKey.split('|');
  if (parts.length != 2) return null;
  final subjectId = parts[0];
  final order = int.tryParse(parts[1]) ?? 0;
  final CoursesRepository repo = ref.watch(coursesRepositoryProvider);
  return repo.getNextLesson(subjectId, order);
});

/// Fetches lesson details with the Subject name joined.
///
/// Strategy: try the full query (with `content` column) first.
/// If it fails (column doesn't exist yet), fall back to the safe query
/// without `content` so the screen still loads.
final lessonDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, lessonId) async {
  ref.keepAlive();

  if (lessonId.isEmpty) {
    throw Exception('Invalid lesson ID (empty).');
  }

  try {
    // Full query — includes the `content` column for the Overview tab.
    // Fetch every localization column for the lesson and the joined subject so
    // the model getters can resolve ar / fr / en correctly.
    final data = await Supabase.instance.client
        .from('lessons')
        .select(
          'id, subject_id, '
          'title, title_ar, title_fr, title_en, '
          'description, description_ar, description_fr, description_en, '
          'content, video_url, duration, order_number, created_at, pdf_url, '
          'subjects(name, name_ar, name_fr, name_en)',
        )
        .eq('id', lessonId)
        .maybeSingle();

    if (data != null) return data;
  } catch (e) {
    // If the error is about the `content` column not existing,
    // retry without it so the screen still loads.
    debugPrint('[LessonDetails] Full query failed: $e — retrying without content column');

    try {
      final fallbackData = await Supabase.instance.client
          .from('lessons')
          .select(
            'id, subject_id, '
            'title, title_ar, title_fr, title_en, '
            'description, description_ar, description_fr, description_en, '
            'video_url, duration, order_number, created_at, pdf_url, '
            'subjects(name, name_ar, name_fr, name_en)',
          )
          .eq('id', lessonId)
          .maybeSingle();

      if (fallbackData != null) return fallbackData;
    } catch (fallbackError) {
      debugPrint('[LessonDetails] Fallback query also failed: $fallbackError');
      throw Exception('Failed to fetch lesson: $fallbackError');
    }
  }

  throw Exception('Lesson not found (id: $lessonId). It may have been deleted.');
});
