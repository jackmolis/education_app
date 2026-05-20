import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/data/supabase_auth_repository.dart';
import 'data/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

/// Fetches the user's note content for a specific lesson.
final noteProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, lessonId) async {
  final repo = ref.watch(notesRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) return null;
  return repo.getNote(userId: user.id, lessonId: lessonId);
});

/// StateNotifier that manages saving notes with debounce.
class NoteController extends StateNotifier<AsyncValue<void>> {
  final NotesRepository _repo;
  final String _userId;
  final String _lessonId;

  NoteController({
    required NotesRepository repo,
    required String userId,
    required String lessonId,
  })  : _repo = repo,
        _userId = userId,
        _lessonId = lessonId,
        super(const AsyncValue.data(null));

  Future<void> save(String content) async {
    state = const AsyncValue.loading();
    try {
      await _repo.saveNote(
        userId: _userId,
        lessonId: _lessonId,
        content: content,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the NoteController, scoped per lesson.
final noteControllerProvider = StateNotifierProvider.autoDispose
    .family<NoteController, AsyncValue<void>, String>((ref, lessonId) {
  final repo = ref.watch(notesRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  return NoteController(
    repo: repo,
    userId: user?.id ?? '',
    lessonId: lessonId,
  );
});
