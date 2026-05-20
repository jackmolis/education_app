import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/realtime_provider.dart';
import '../../domain/live_activity_model.dart';

class LiveActivitySection extends ConsumerWidget {
  const LiveActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Explicitly scope the realtime watch so it avoids rebuilding the entire parent AdminDashboardScreen 
    final activities = ref.watch(realtimeProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Live Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.red, size: 10),
                  const SizedBox(width: 4),
                  const Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
           Container(
             padding: const EdgeInsets.all(32),
             alignment: Alignment.center,
             decoration: BoxDecoration(
               color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
               borderRadius: BorderRadius.circular(16),
             ),
             child: const Text('Searching for activity...', style: TextStyle(color: Colors.grey)),
           )
        else
           AnimatedSize(
             duration: const Duration(milliseconds: 300),
             alignment: Alignment.topCenter,
             child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                   final activity = activities[index];
                   return _ActivityTile(key: ValueKey(activity.id), activity: activity);
                },
             ),
           ),
      ],
    );
  }
}

class _ActivityTile extends StatefulWidget {
  final LiveActivityModel activity;
  
  const _ActivityTile({super.key, required this.activity});

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    final isQuiz = widget.activity.type == ActivityType.quiz;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isQuiz ? Colors.purple : Colors.blue).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isQuiz ? Icons.quiz_rounded : Icons.play_circle_fill_rounded,
                  color: isQuiz ? Colors.purple : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.description,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Just now',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
