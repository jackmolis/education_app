import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/authentication/data/supabase_auth_repository.dart';
import '../../data/video_progress_repository.dart';
import '../../domain/models/video_progress_model.dart';

final videoProgressRepositoryProvider = Provider<VideoProgressRepository>((ref) {
  return VideoProgressRepository();
});

/// Returns the saved video progress for a specific lesson (null if never watched).
final lessonVideoProgressProvider =
    FutureProvider.autoDispose.family<VideoProgressModel?, String>((ref, lessonId) async {
  final repo = ref.watch(videoProgressRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) return null;
  return repo.getProgress(userId: user.id, lessonId: lessonId);
});

/// Returns the most recently watched lesson (for the Dashboard card).
final lastWatchedProvider = FutureProvider.autoDispose<VideoProgressModel?>((ref) async {
  final repo = ref.watch(videoProgressRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) return null;
  return repo.getLastWatched(user.id);
});

/// Returns weekly activity counts (Mon→Sun) from video_progress table.
final weeklyProgressProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final repo = ref.watch(videoProgressRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) return List<int>.filled(7, 0);
  return repo.getWeeklyProgress(user.id);
});

/// Returns the user's current consecutive-day learning streak.
final streakProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(videoProgressRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  if (user == null) return 0;
  return repo.getUserStreak(user.id);
});
