import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_providers.dart';
import '../../../courses/domain/models/exam_model.dart';
import '../../../courses/domain/models/exam_model_entity.dart';

/// Admin exam filter: optional subject + optional semester.
typedef AdminExamsFilter = ({String? subjectId, int? semester});

/// Exams for the admin management screen, filtered by subject/semester.
final adminExamsProvider =
    FutureProvider.family<List<ExamModel>, AdminExamsFilter>((ref, filter) async {
  final repo = ref.watch(adminRepositoryProvider);
  final raw = await repo.getExamsForAdmin(
    subjectId: filter.subjectId,
    semester: filter.semester,
  );
  return raw.map((json) => ExamModel.fromJson(json)).toList();
});

/// Flat list of ALL exams (no filter) — used for the exam-selector dropdown
/// in the Add/Edit Exam Model screen.
final allExamsForSelectorProvider =
    FutureProvider<List<ExamModel>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final raw = await repo.getExamsForAdmin();
  return raw.map((json) => ExamModel.fromJson(json)).toList();
});

/// Models belonging to an exam (admin management screen).
final adminExamModelsProvider =
    FutureProvider.family<List<ExamModelEntity>, String>((ref, examId) async {
  final repo = ref.watch(adminRepositoryProvider);
  final raw = await repo.getExamModelsForAdmin(examId);
  return raw.map((json) => ExamModelEntity.fromJson(json)).toList();
});
