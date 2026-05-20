import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_quiz_summary_model.dart';
import '../../data/admin_providers.dart';

final manageQuizzesStateProvider = AsyncNotifierProvider<ManageQuizzesNotifier, List<AdminQuizSummaryModel>>(ManageQuizzesNotifier.new);

class ManageQuizzesNotifier extends AsyncNotifier<List<AdminQuizSummaryModel>> {
  @override
  Future<List<AdminQuizSummaryModel>> build() async {
    return _fetchQuizzes();
  }

  Future<List<AdminQuizSummaryModel>> _fetchQuizzes() async {
    final repository = ref.read(adminRepositoryProvider);
    return await repository.getQuizzesSummary();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchQuizzes);
  }

  Future<void> deleteQuiz(String lessonId) async {
    final repository = ref.read(adminRepositoryProvider);
    await repository.deleteQuiz(lessonId);
    await refresh();
  }
}

final quizSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredQuizzesProvider = Provider<List<AdminQuizSummaryModel>>((ref) {
  final quizzesState = ref.watch(manageQuizzesStateProvider);
  final searchQuery = ref.watch(quizSearchQueryProvider).toLowerCase();

  return quizzesState.maybeWhen(
    data: (quizzes) {
      if (searchQuery.isEmpty) return quizzes;
      return quizzes.where((q) {
        return q.lessonName.toLowerCase().contains(searchQuery) ||
               q.subjectName.toLowerCase().contains(searchQuery);
      }).toList();
    },
    orElse: () => [],
  );
});
