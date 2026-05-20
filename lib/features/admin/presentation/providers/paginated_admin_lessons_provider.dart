import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../data/admin_providers.dart';

class PaginatedLessonsState {
  final List<LessonModel> lessons;
  final bool hasMore;
  final bool isFetchingMore;

  PaginatedLessonsState({
    required this.lessons,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  PaginatedLessonsState copyWith({
    List<LessonModel>? lessons,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return PaginatedLessonsState(
      lessons: lessons ?? this.lessons,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}

class AdminLessonsFilter {
  final String? subjectId;
  final String? searchQuery;

  const AdminLessonsFilter({this.subjectId, this.searchQuery});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminLessonsFilter && runtimeType == other.runtimeType && subjectId == other.subjectId && searchQuery == other.searchQuery;

  @override
  int get hashCode => subjectId.hashCode ^ searchQuery.hashCode;
}

class PaginatedAdminLessonsNotifier extends FamilyAsyncNotifier<PaginatedLessonsState, AdminLessonsFilter> {
  static const int _limit = 15;

  @override
  Future<PaginatedLessonsState> build(AdminLessonsFilter arg) async {
    final repository = ref.watch(adminRepositoryProvider);
    final rawData = await repository.getPaginatedLessons(
      limit: _limit,
      offset: 0,
      subjectId: arg.subjectId,
      searchQuery: arg.searchQuery,
    );
    final initialLessons = rawData.map((e) => LessonModel.fromJson(e)).toList();

    return PaginatedLessonsState(
      lessons: initialLessons,
      hasMore: initialLessons.length == _limit,
    );
  }

  Future<void> loadMore() async {
    final currentVal = state.valueOrNull;
    if (currentVal == null || !currentVal.hasMore || currentVal.isFetchingMore) return;

    state = AsyncValue.data(currentVal.copyWith(isFetchingMore: true));

    try {
      final repository = ref.read(adminRepositoryProvider);
      final offset = currentVal.lessons.length;
      final rawData = await repository.getPaginatedLessons(
        limit: _limit,
        offset: offset,
        subjectId: arg.subjectId,
        searchQuery: arg.searchQuery,
      );
      final newLessons = rawData.map((e) => LessonModel.fromJson(e)).toList();

      state = AsyncValue.data(
        currentVal.copyWith(
          lessons: [...currentVal.lessons, ...newLessons],
          hasMore: newLessons.length == _limit,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(currentVal.copyWith(
        isFetchingMore: false,
        hasMore: false, // Prevent infinite network locks on fail
      ));
    }
  }
  
  void removeLocalLesson(String lessonId) {
    final currentVal = state.valueOrNull;
    if (currentVal == null) return;
    
    final updated = currentVal.lessons.where((l) => l.id != lessonId).toList();
    state = AsyncValue.data(currentVal.copyWith(lessons: updated));
  }
}

final paginatedAdminLessonsProvider = AsyncNotifierProviderFamily<PaginatedAdminLessonsNotifier, PaginatedLessonsState, AdminLessonsFilter>(() {
  return PaginatedAdminLessonsNotifier();
});
