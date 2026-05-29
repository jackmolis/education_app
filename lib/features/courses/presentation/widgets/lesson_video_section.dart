import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lesson_model.dart';
import '../providers/storage_provider.dart';
import '../../../authentication/domain/auth_repository.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../../video_progress/data/video_progress_repository.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';
import 'lesson_video_player.dart';
import 'lesson_details/video_card.dart';

/// Isolated video section.
///
/// This widget watches ONLY the signed media URL provider. It deliberately does
/// NOT watch `completedLessonIdsProvider` or `nextLessonProvider`, so updates to
/// lesson completion / next-lesson state never rebuild the video player or
/// recreate the ExoPlayer / WebView controller.
///
/// The initial playback position is captured exactly ONCE during initialization
/// and is never made reactive afterwards.
class LessonVideoSection extends ConsumerStatefulWidget {
  final LessonModel lesson;

  /// Resume position supplied by navigation (e.g. "continue watching").
  /// Used only as the initial seek point — captured once at init.
  final double initialPositionSeconds;

  const LessonVideoSection({
    super.key,
    required this.lesson,
    required this.initialPositionSeconds,
  });

  @override
  ConsumerState<LessonVideoSection> createState() => LessonVideoSectionState();
}

class LessonVideoSectionState extends ConsumerState<LessonVideoSection> {
  final GlobalKey<dynamic> _videoPlayerKey = GlobalKey();

  /// Captured ONCE during init — never reactive afterwards.
  late final double _startPosition;

  /// Repositories captured ONCE during init.
  ///
  /// These are plain `Provider`s (no rebuild side effects), so reading them a
  /// single time here is safe. Caching them means the `onPositionChanged`
  /// callback — which can fire during the player's `dispose()` — never calls
  /// `ref.read()` after this widget has been deactivated. That deactivation is
  /// exactly what triggered the
  /// "Looking up a deactivated widget's ancestor is unsafe" /
  /// `ProviderScope.containerOf` crash on navigation.
  late final AuthRepository _authRepo;
  late final VideoProgressRepository _videoProgressRepo;

  @override
  void initState() {
    super.initState();
    // Cache repositories once — safe to read plain Providers here, and avoids
    // touching `ref` during dispose-time callbacks.
    _authRepo = ref.read(authRepositoryProvider);
    _videoProgressRepo = ref.read(videoProgressRepositoryProvider);

    // Resolve the initial position a single time:
    //  1. Navigation param (continue-watching deep link), else
    //  2. The saved DB progress if already cached.
    final saved = ref.read(lessonVideoProgressProvider(widget.lesson.id)).value;
    _startPosition = widget.initialPositionSeconds > 0
        ? widget.initialPositionSeconds
        : (saved?.positionSeconds ?? 0.0);
  }

  /// Allows the parent screen to persist progress on exit without holding a
  /// reference to the underlying player widget.
  Future<void> saveCurrentProgress() async {
    final state = _videoPlayerKey.currentState;
    if (state != null) {
      await state.saveCurrentProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    if (lesson.videoUrl.isEmpty) {
      return _placeholder('No video available');
    }

    final isYoutube = lesson.videoUrl.contains('youtube.com') ||
        lesson.videoUrl.contains('youtu.be');

    if (isYoutube) {
      return _buildCard(lesson.videoUrl);
    }

    // Watch ONLY the signed media URL provider.
    return ref.watch(lessonMediaUrlProvider(lesson.videoUrl)).when(
          data: (signedUrl) => _buildCard(signedUrl),
          loading: () => _placeholder(null, isLoading: true),
          error: (_, __) => _placeholder('Failed to load video'),
        );
  }

  Widget _buildCard(String url) {
    final lesson = widget.lesson;
    return VideoCard(
      videoPlayer: LessonVideoPlayer(
        key: _videoPlayerKey,
        sourceIdentity: lesson.videoUrl,
        videoUrl: url,
        startPositionSeconds: _startPosition,
        onPositionChanged: (position, duration) {
          // Fire-and-forget — does not block playback, does not invalidate
          // any provider during playback.
          //
          // Uses the repositories cached in initState (NOT `ref.read`) so this
          // is safe even when invoked from the player's dispose() after this
          // widget has been deactivated during navigation.
          final user = _authRepo.currentUser;
          if (user == null) return;
          _videoProgressRepo
              .saveProgress(
                userId: user.id,
                lessonId: lesson.id,
                subjectId: lesson.subjectId,
                positionSeconds: position,
                durationSeconds: duration,
              )
              .catchError((_) {});
        },
      ),
    );
  }

  Widget _placeholder(String? message, {bool isLoading = false}) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isLoading ? Colors.black12 : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                message ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
      ),
    );
  }
}
