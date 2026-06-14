import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nexora_academy/features/courses/domain/models/subject_model.dart';
import 'package:nexora_academy/features/courses/domain/models/level_model.dart';
import 'package:nexora_academy/features/courses/data/subjects_repository.dart';

// NOT autoDispose — levels rarely change and should persist across navigation.
final levelsProvider = FutureProvider<List<LevelModel>>((ref) async {
  final response = await Supabase.instance.client.from('levels').select('id, name').order('name');
  return (response as List).map((json) => LevelModel.fromJson(json as Map<String, dynamic>)).toList();
});

typedef SubjectsQueryArgs = ({String levelId, String? streamId, String? optionLang});
typedef OptionsQueryArgs = ({String levelId, String? streamId});
final optionsByLevelProvider =
FutureProvider.family<List<String>, OptionsQueryArgs>((ref, args) async {
  final supabase = Supabase.instance.client;

  var query = supabase
      .from('subjects')
      .select('option_lang')
      .eq('level_id', args.levelId);

  if (args.streamId != null) {
    query = query.eq('stream_id', args.streamId!);
  }

  final response = await query;

  final data = response as List;

  final options = data
      .map((e) => e['option_lang'] as String?)
      .where((e) => e != null && e.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();

  return options;
});

final subjectsByLevelProvider =
    FutureProvider.family<List<SubjectModel>, SubjectsQueryArgs>((ref, args) async {
  final repository = ref.read(subjectsRepositoryProvider);
  return repository.getSubjectsByLevel(args.levelId, streamId: args.streamId, optionLang: args.optionLang);
});

// ─── Paginated subjects ───────────────────────────────────────────────────────

const _kSubjectsPageSize = 20;

class PaginatedSubjectsState {
  final List<SubjectModel> subjects;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const PaginatedSubjectsState({
    this.subjects = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  static const _sentinel = Object();

  PaginatedSubjectsState copyWith({
    List<SubjectModel>? subjects,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _sentinel,
  }) {
    return PaginatedSubjectsState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _sentinel) ? this.error : error,
    );
  }
}

class PaginatedSubjectsNotifier
    extends StateNotifier<PaginatedSubjectsState> {
  final SubjectsRepository _repository;
  final SubjectsQueryArgs _args;
  int _currentPage = 0;

  PaginatedSubjectsNotifier(this._repository, this._args)
      : super(const PaginatedSubjectsState()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repository.getSubjectsByLevelPaginated(
        _args.levelId,
        streamId: _args.streamId,
        optionLang: _args.optionLang,
        page: 0,
        pageSize: _kSubjectsPageSize,
      );
      _currentPage = 0;
      state = state.copyWith(
        subjects: results,
        isLoading: false,
        hasMore: results.length == _kSubjectsPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = _currentPage + 1;
      final results = await _repository.getSubjectsByLevelPaginated(
        _args.levelId,
        streamId: _args.streamId,
        optionLang: _args.optionLang,
        page: nextPage,
        pageSize: _kSubjectsPageSize,
      );
      _currentPage = nextPage;
      state = state.copyWith(
        subjects: [...state.subjects, ...results],
        isLoadingMore: false,
        hasMore: results.length == _kSubjectsPageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    await _loadInitial();
  }
}

final paginatedSubjectsByLevelProvider = StateNotifierProvider.family
    .autoDispose<PaginatedSubjectsNotifier, PaginatedSubjectsState, SubjectsQueryArgs>(
  (ref, args) {
    final repository = ref.read(subjectsRepositoryProvider);
    return PaginatedSubjectsNotifier(repository, args);
  },
);
