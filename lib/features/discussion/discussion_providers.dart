import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/discussion_repository.dart';

final discussionRepositoryProvider = Provider<DiscussionRepository>((ref) {
  return DiscussionRepository();
});

/// Real-time stream of comments for a lesson.
/// NOT autoDispose — keeps the stream alive across tab switches in TabBarView.
final commentsStreamProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, lessonId) {
  debugPrint('[Discussion] commentsStreamProvider created for: $lessonId');
  final repo = ref.watch(discussionRepositoryProvider);
  return repo.watchComments(lessonId);
});
