import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/admin_quiz_summary_model.dart';
import '../../quizzes/domain/quiz_model.dart';
class AdminRepository {
  final SupabaseClient _supabaseClient;

  AdminRepository(this._supabaseClient);

  /// Returns the next order_number for [subjectId]: max(order_number) + 1, or 1 if no lessons.
  Future<int> getNextOrderNumber(String subjectId) async {
    try {
      final res = await _supabaseClient
          .from('lessons')
          .select('order_number')
          .eq('subject_id', subjectId)
          .order('order_number', ascending: false)
          .limit(1);
      if (res.isEmpty) return 1;
      final maxOrder = res.first['order_number'] as int?;
      return (maxOrder ?? 0) + 1;
    } catch (e) {
      throw Exception('Failed to get next order number: $e');
    }
  }

  Future<void> addLesson(Map<String, dynamic> lessonData) async {
    try {
      // Insert lesson — the Supabase trigger `notify_new_lesson`
      // automatically creates one notification per user.
      await _supabaseClient
          .from('lessons')
          .insert(lessonData);
    } catch (e) {
      throw Exception('Failed to add lesson: $e');
    }
  }

  Future<void> addSubject(String name) async {
    try {
      await _supabaseClient
          .from('subjects')
          .insert({'name': name});
    } catch (e) {
      throw Exception('Failed to add subject: $e');
    }
  }

  Future<String> uploadSubjectImageBytes(Uint8List bytes, String extension) async {
    const bucketId = 'subjects';
    final safeExt = extension.replaceAll('.', '').toLowerCase();
    final path = 'subjects/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    await _supabaseClient.storage.from(bucketId).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: false),
    );
    return _supabaseClient.storage.from(bucketId).getPublicUrl(path);
  }

  Future<void> addSubjectWithDetails(Map<String, dynamic> subjectData) async {
    try {
      await _supabaseClient
          .from('subjects')
          .insert(subjectData);
    } catch (e) {
      throw Exception('Failed to add subject: $e');
    }
  }

  Future<void> addQuiz(Map<String, dynamic> quizData) async {
    try {
      await _supabaseClient
          .from('quizzes')
          .insert(quizData);
    } catch (e) {
      throw Exception('Failed to add quiz: $e');
    }
  }

  Future<void> addQuizzes(List<Map<String, dynamic>> quizzesData) async {
    try {
      await _supabaseClient
          .from('quizzes')
          .insert(quizzesData);
    } catch (e) {
      throw Exception('Failed to add quizzes: $e');
    }
  }

  Future<void> updateSubject(String subjectId, Map<String, dynamic> data) async {
    try {
      await _supabaseClient
          .from('subjects')
          .update(data)
          .eq('id', subjectId);
    } catch (e) {
      throw Exception('Failed to update subject: $e');
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _supabaseClient
          .from('subjects')
          .delete()
          .eq('id', subjectId);
    } catch (e) {
      throw Exception('Failed to delete subject: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllLessons() async {
    try {
      final data = await _supabaseClient
          .from('lessons')
          .select(
            'id, subject_id, title_en, title_fr, title_ar, video_url, pdf_url, order_number, created_at',
          )
          .order('subject_id', ascending: true)
          .order('order_number', ascending: true);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw Exception('Failed to fetch all lessons: $e');
    }
  }

  /// Paginated lessons for admin screens (filter by subject / search).
  Future<List<Map<String, dynamic>>> getPaginatedLessons({
    required int limit,
    required int offset,
    String? subjectId,
    String? searchQuery,
  }) async {
    try {
      dynamic query = _supabaseClient.from('lessons').select(
            'id, subject_id, title_en, title_fr, title_ar, video_url, pdf_url, order_number, created_at',
          );

      if (subjectId != null && subjectId.isNotEmpty) {
        query = query.eq('subject_id', subjectId);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or('title_en.ilike.%${searchQuery.trim()}%,title_fr.ilike.%${searchQuery.trim()}%,title_ar.ilike.%${searchQuery.trim()}%');
      }

      final data = await query
          .order('order_number', ascending: true)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw Exception('Failed to fetch paginated lessons: $e');
    }
  }

  Future<void> updateLesson(String lessonId, Map<String, dynamic> data) async {
    try {
      await _supabaseClient
          .from('lessons')
          .update(data)
          .eq('id', lessonId);
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await _supabaseClient
          .from('lessons')
          .delete()
          .eq('id', lessonId);
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  Future<void> updateLessonOrders(List<Map<String, dynamic>> updates) async {
    try {
      await Future.wait(updates.map((update) => 
        _supabaseClient
            .from('lessons')
            .update({'order_number': update['order_number']})
            .eq('id', update['id'])
      ));
    } catch (e) {
      throw Exception('Failed to update lesson orders: $e');
    }
  }

  Future<List<AdminQuizSummaryModel>> getQuizzesSummary({int? limit, int? offset}) async {
    try {
      const selectCols =
          'id, lesson_id, question, options, correct_answer, created_at, lessons(id, title_en, title_fr, title_ar, subjects(id, name_en, name_fr, name_ar))';

      final List<dynamic> data;
      if (limit != null && offset != null) {
        data = await _supabaseClient
            .from('quizzes')
            .select(selectCols)
            .range(offset, offset + limit - 1);
      } else {
        data = await _supabaseClient.from('quizzes').select(selectCols);
      }

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var row in data) {
        final lessonId = row['lesson_id'].toString();
        grouped.putIfAbsent(lessonId, () => []).add(row);
      }

      final List<AdminQuizSummaryModel> summaries = [];
      for (var entry in grouped.entries) {
        final lessonId = entry.key;
        final rows = entry.value;

        String lessonTitle = 'Unknown Lesson';
        String subjectName = 'Unknown Subject';

        if (rows.isNotEmpty) {
           final first = rows.first;
           final lessonData = first['lessons'];
           if (lessonData != null) {
              lessonTitle = lessonData['title_en']?.toString() ?? 'Unknown Lesson';
              final subjectData = lessonData['subjects'];
              if (subjectData != null) {
                 subjectName = subjectData['name_en']?.toString() ?? 'Unknown Subject';
              }
           }
        }

        final questions = rows.map((r) => QuizModel.fromJson(r)).toList();
        
        summaries.add(AdminQuizSummaryModel(
          lessonId: lessonId,
          lessonName: lessonTitle,
          subjectName: subjectName,
          questions: questions,
        ));
      }

      summaries.sort((a, b) {
        int subCmp = a.subjectName.compareTo(b.subjectName);
        if (subCmp != 0) return subCmp;
        return a.lessonName.compareTo(b.lessonName);
      });

      return summaries;
    } catch (e) {
      throw Exception('Failed to fetch quizzes summary: $e');
    }
  }

  Future<void> deleteQuiz(String lessonId) async {
    try {
      await _supabaseClient
          .from('quizzes')
          .delete()
          .eq('lesson_id', lessonId);
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }
}
