import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/tap_scale_wrapper.dart';
import '../../../video_progress/presentation/providers/video_progress_provider.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class LessonCard extends ConsumerWidget {
  final String title;
  final String lessonId;
  final int orderNumber;
  final int? durationMinutes;
  final bool isCompleted;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.title,
    required this.lessonId,
    required this.orderNumber,
    this.durationMinutes,
    this.isCompleted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(lessonVideoProgressProvider(lessonId));

    // Derive real progress values
    final videoProgress = progressAsync.valueOrNull;
    final double progressFraction;
    final String statusText;
    final String durationText;

    if (isCompleted) {
      progressFraction = 1.0;
      statusText = loc.completed;
    } else if (videoProgress != null && videoProgress.positionSeconds > 0) {
      progressFraction = videoProgress.progressFraction;
      statusText = loc.inProgress;
    } else {
      progressFraction = 0.0;
      statusText = loc.notStarted;
    }

    // Build duration display
    if (videoProgress != null && videoProgress.durationSeconds > 0) {
      durationText = _formatDuration(videoProgress.durationSeconds.toInt());
    } else if (durationMinutes != null && durationMinutes! > 0) {
      durationText = '$durationMinutes ${loc.minShort}';
    } else {
      durationText = loc.videoLesson;
    }

    // Status color
    final Color statusColor;
    if (isCompleted) {
      statusColor = const Color(0xFF4CAF50);
    } else if (progressFraction > 0) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF94A3B8);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TapScaleWrapper(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Circular Order Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFF4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 22)
                        : Text(
                            orderNumber.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content Center Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Duration + Status row
                      Row(
                        children: [
                          Icon(Icons.play_circle_outline_rounded,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              durationText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          backgroundColor: Colors.grey.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF4A90E2),
                          ),
                          minHeight: 4,
                        ),
                      ),

                      // Watched time (only if in progress)
                      if (videoProgress != null &&
                          videoProgress.positionSeconds > 0 &&
                          !isCompleted) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${_formatDuration(videoProgress.positionSeconds.toInt())} / ${_formatDuration(videoProgress.durationSeconds.toInt())}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Play Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                          : [const Color(0xFF9013FE), const Color(0xFF4A90E2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    videoProgress != null && videoProgress.positionSeconds > 0 && !isCompleted
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
