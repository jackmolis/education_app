import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/lesson_model.dart';
import '../providers/storage_provider.dart';
import 'lesson_video_player.dart';

class LessonVideoCard extends ConsumerWidget {
  final LessonModel lesson;
  final double startPositionSeconds;
  final void Function(double position, double duration)? onPositionChanged;

  const LessonVideoCard({
    super.key,
    required this.lesson,
    required this.startPositionSeconds,
    this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lesson.videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final isYouTube = lesson.videoUrl.contains('youtube.com') ||
        lesson.videoUrl.contains('youtu.be');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isYouTube
            ? LessonVideoPlayer(
                key: ValueKey('lesson-video-${lesson.id}'),
                sourceIdentity: lesson.videoUrl,
                videoUrl: lesson.videoUrl,
                startPositionSeconds: startPositionSeconds,
                onPositionChanged: onPositionChanged,
              )
            : ref.watch(lessonMediaUrlProvider(lesson.videoUrl)).when(
                  data: (signedUrl) => LessonVideoPlayer(
                    key: ValueKey('lesson-video-${lesson.id}'),
                    sourceIdentity: lesson.videoUrl,
                    videoUrl: signedUrl,
                    startPositionSeconds: startPositionSeconds,
                    onPositionChanged: onPositionChanged,
                  ),
                  loading: () => Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (error, stack) => Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.error_outline,
                              color: Colors.white, size: 40),
                          SizedBox(height: 12),
                          Text(
                            'Failed to load video.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
