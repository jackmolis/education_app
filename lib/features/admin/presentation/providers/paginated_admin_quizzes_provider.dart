import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/admin_quiz_summary_model.dart';
import '../../data/admin_providers.dart';

class PaginatedQuizzesState {
  final List<AdminQuizSummaryModel> quizzes;
  final bool hasMore;
  final bool isFetchingMore;

  PaginatedQuizzesState({
    required this.quizzes,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  PaginatedQuizzesState copyWith({
    List<AdminQuizSummaryModel>? quizzes,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return PaginatedQuizzesState(
      quizzes: quizzes ?? this.quizzes,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class PaginatedAdminQuizzesNotifier extends AsyncNotifier<PaginatedQuizzesState> {
  static const int _limit = 10; // Load 10 summary objects at a time

  @override
  Future<PaginatedQuizzesState> build() async {
    final repository = ref.watch(adminRepositoryProvider);
    final initialQuizzes = await repository.getQuizzesSummary(limit: _limit, offset: 0);

    return PaginatedQuizzesState(
      quizzes: initialQuizzes,
      hasMore: initialQuizzes.length == _limit,
    );
  }

  Future<void> loadMore() async {
    final currentVal = state.valueOrNull;
    if (currentVal == null || !currentVal.hasMore || currentVal.isFetchingMore) return;

    state = AsyncValue.data(currentVal.copyWith(isFetchingMore: true));

    try {
      final repository = ref.read(adminRepositoryProvider);
      final offset = currentVal.quizzes.length;
      final newQuizzes = await repository.getQuizzesSummary(
        limit: _limit,
        offset: offset,
      );

      state = AsyncValue.data(
        currentVal.copyWith(
          quizzes: [...currentVal.quizzes, ...newQuizzes],
          hasMore: newQuizzes.length == _limit,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(currentVal.copyWith(
        isFetchingMore: false,
        hasMore: false,
      ));
    }
  }

  Future<void> deleteQuiz(String lessonId) async {
    final repository = ref.read(adminRepositoryProvider);
    await repository.deleteQuiz(lessonId);
    
    final currentVal = state.valueOrNull;
    if (currentVal != null) {
      final updated = currentVal.quizzes.where((q) => q.lessonId != lessonId).toList();
      state = AsyncValue.data(currentVal.copyWith(quizzes: updated));
    }
  }
  
  void refresh() {
    ref.invalidateSelf();
  }
}

final paginatedAdminQuizzesProvider = AsyncNotifierProvider<PaginatedAdminQuizzesNotifier, PaginatedQuizzesState>(PaginatedAdminQuizzesNotifier.new);

// Derive filtering synchronously
final quizSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPaginatedQuizzesProvider = Provider<PaginatedQuizzesState?>((ref) {
  final paginatedState = ref.watch(paginatedAdminQuizzesProvider).valueOrNull;
  if (paginatedState == null) return null;
  
  final searchQuery = ref.watch(quizSearchQueryProvider).toLowerCase();
  
  if (searchQuery.isEmpty) return paginatedState;
  
  final filteredList = paginatedState.quizzes.where((q) {
    return q.lessonName.toLowerCase().contains(searchQuery) ||
           q.subjectName.toLowerCase().contains(searchQuery);
  }).toList();
  
  return paginatedState.copyWith(quizzes: filteredList);
});
