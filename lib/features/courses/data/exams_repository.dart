import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/exam_model.dart';
import '../domain/models/exam_model_entity.dart';

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  return ExamsRepository();
});

class ExamsRepository {
  final SupabaseClient _supabase;

  ExamsRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  static const String _selectCols =
      'id, subject_id, semester, '
      'title_en, title_fr, title_ar, '
      'description_en, description_fr, description_ar, '
      'order_number, created_at';

  /// Exams for [subjectId] in [semester] (1 or 2), ordered by order_number.
  Future<List<ExamModel>> getExams({
    required String subjectId,
    required int semester,
  }) async {
    try {
      final data = await _supabase
          .from('exams')
          .select(_selectCols)
          .eq('subject_id', subjectId)
          .eq('semester', semester)
          .order('order_number', ascending: true);

      return (data as List)
          .map((json) => ExamModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Exams] getExams failed: $e');
      throw Exception('Failed to fetch exams: $e');
    }
  }

  static const String _modelSelectCols =
      'id, exam_id, model_number, title_en, title_fr, title_ar, '
      'exam_pdf_url, correction_pdf_url, created_at';

  /// All models belonging to [examId], ordered by model_number.
  Future<List<ExamModelEntity>> getExamModels(String examId) async {
    try {
      final data = await _supabase
          .from('exam_models')
          .select(_modelSelectCols)
          .eq('exam_id', examId)
          .order('model_number', ascending: true);

      return (data as List)
          .map((json) => ExamModelEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Exams] getExamModels failed: $e');
      throw Exception('Failed to fetch exam models: $e');
    }
  }
}
