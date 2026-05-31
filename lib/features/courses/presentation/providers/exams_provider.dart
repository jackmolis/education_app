import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exam_model.dart';
import '../../domain/models/exam_model_entity.dart';
import '../../data/exams_repository.dart';

/// Query args for fetching exams: subject + semester (1 or 2).
typedef ExamsQueryArgs = ({String subjectId, int semester});

/// Exams for a subject in a given semester.
final examsProvider =
    FutureProvider.family<List<ExamModel>, ExamsQueryArgs>((ref, args) async {
  final repo = ref.watch(examsRepositoryProvider);
  return repo.getExams(subjectId: args.subjectId, semester: args.semester);
});

/// Models (Modèles / النماذج) belonging to a single exam.
final examModelsProvider =
    FutureProvider.family<List<ExamModelEntity>, String>((ref, examId) async {
  final repo = ref.watch(examsRepositoryProvider);
  return repo.getExamModels(examId);
});
