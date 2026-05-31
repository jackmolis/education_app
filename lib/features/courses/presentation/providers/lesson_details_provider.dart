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

/// Fetches lesson details with the localized subject names joined.
///
/// Only localized columns are selected — legacy `title` / `description` /
/// `content` (lessons) and `name` (subjects) are intentionally not fetched.
final lessonDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, lessonId) async {
  ref.keepAlive();

  if (lessonId.isEmpty) {
    throw Exception('Invalid lesson ID (empty).');
  }

  try {
    final data = await Supabase.instance.client
        .from('lessons')
        .select(
          'id, subject_id, '
          'title_ar, title_fr, title_en, '
          'description_ar, description_fr, description_en, '
          'video_url, duration, order_number, created_at, pdf_url, '
          'subjects(name_ar, name_fr, name_en)',
        )
        .eq('id', lessonId)
        .maybeSingle();

    if (data != null) return data;
  } catch (e) {
    debugPrint('[LessonDetails] Query failed: $e');
    throw Exception('Failed to fetch lesson: $e');
  }

  throw Exception('Lesson not found (id: $lessonId). It may have been deleted.');
});
