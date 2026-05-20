import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/quiz_model.dart';
import '../../data/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

// A FutureProvider to load a list of QuizModel (questions) for a specific lessonId
final quizFutureProvider = FutureProvider.family<List<QuizModel>, String>((
  ref,
  lessonId,
) async {
  final repository = ref.watch(quizRepositoryProvider);
  return repository.getQuizByLessonId(lessonId);
});

class QuizState {
  final int currentIndex;
  final int score;
  final bool isCompleted;

  QuizState({this.currentIndex = 0, this.score = 0, this.isCompleted = false});

  QuizState copyWith({int? currentIndex, int? score, bool? isCompleted}) {
    return QuizState(
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final List<QuizModel> questions;

  QuizNotifier(this.questions) : super(QuizState());

  Future<void> answerQuestion(
    String selectedAnswer,
    String lessonId,
    QuizRepository repository,
  ) async {
    if (state.isCompleted) return;

    final currentQuestion = questions[state.currentIndex];
    int newScore = state.score;

    bool isCorrect = false;
    if (currentQuestion.type == 'shortAnswer') {
      isCorrect = currentQuestion.correctAnswer.trim().toLowerCase() == selectedAnswer.trim().toLowerCase();
    } else {
      isCorrect = currentQuestion.correctAnswer == selectedAnswer;
    }

    if (isCorrect) {
      newScore++;
    }

    if (state.currentIndex < questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        score: newScore,
      );
    } else {
      state = state.copyWith(score: newScore, isCompleted: true);
      // Save to Supabase
      try {
        await repository.saveQuizResult(
          lessonId: lessonId,
          score: newScore,
          total: questions.length,
        );
      } catch (e) {
        // Just print the error, user can still see result screen
        debugPrint('Could not save result: $e');
      }
    }
  }

  void reset() {
    state = QuizState();
  }
}

final quizProvider =
    StateNotifierProvider.family<QuizNotifier, QuizState, List<QuizModel>>((
      ref,
      questions,
    ) {
      return QuizNotifier(questions);
    });
