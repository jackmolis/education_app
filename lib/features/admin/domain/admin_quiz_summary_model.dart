import '../../quizzes/domain/quiz_model.dart';

class AdminQuizSummaryModel {
  final String lessonId;
  final String lessonName;
  final String subjectName;
  final List<QuizModel> questions;

  AdminQuizSummaryModel({
    required this.lessonId,
    required this.lessonName,
    required this.subjectName,
    required this.questions,
  });

  int get totalQuestions => questions.length;
  
  int get timeLimit {
    if (questions.isEmpty) return 0;
    return questions.first.timeLimit; // Aggregate first node time-limit safely
  }
}
