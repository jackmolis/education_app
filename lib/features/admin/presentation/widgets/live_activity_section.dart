import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/realtime_provider.dart';
import '../../domain/live_activity_model.dart';

class LiveActivitySection extends ConsumerWidget {
  const LiveActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(realtimeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time platform events',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Live badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Activity feed
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 36,
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                ),
                const SizedBox(height: 12),
                Text(
                  'Listening for activity...',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New events will appear here in real-time',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.topCenter,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityTile(
                  key: ValueKey(activity.id),
                  activity: activity,
                );
              },
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _PulsingDot — Animated pulsing indicator
// ═══════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFEF4444),
              const Color(0xFFEF4444).withOpacity(0.4),
              _controller.value,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.4 * (1 - _controller.value)),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _ActivityTile — Individual activity item with animation
// ═══════════════════════════════════════════════════════════════

class _ActivityTile extends StatefulWidget {
  final LiveActivityModel activity;

  const _ActivityTile({super.key, required this.activity});

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isQuiz = widget.activity.type == ActivityType.quiz;

    final Color accentColor = isQuiz
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF0EA5E9);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isQuiz ? Icons.quiz_rounded : Icons.play_circle_fill_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTimestamp(widget.activity.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isQuiz ? 'Quiz' : 'Video',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
