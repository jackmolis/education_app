import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../../core/widgets/shimmer_loaders.dart';
import '../../../../core/widgets/tap_scale_wrapper.dart';

class RecentLessonsSection extends ConsumerWidget {
  const RecentLessonsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentLessonsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Lessons',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              GestureDetector(
                onTap: () => context.go('/subjects'),
                child: const Text(
                  'See All',
                  style: TextStyle(color: Color(0xFF4A6CF7), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          recentAsync.when(
            data: (lessons) {
              if (lessons.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.play_circle_outline, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No recent lessons yet',
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  final color = [
                    const Color(0xFF4A6CF7),
                    const Color(0xFF10B981),
                    const Color(0xFFFF8A00),
                    const Color(0xFF7C3AED),
                    const Color(0xFFEF4444),
                  ][index % 5];

                  return TapScaleWrapper(
                    onTap: () {
                      context.push('/subjects/${lesson.subjectId}/lessons/${lesson.id}/details', extra: lesson);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.play_circle_fill_rounded, color: color, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.getTitle(Localizations.localeOf(context).languageCode),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Lesson ${lesson.orderNumber}',
                                          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.circle, size: 4, color: Colors.grey[300]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tap to view',
                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 24),
                            ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const ShimmerListLoader(itemCount: 3, itemHeight: 76),
            error: (error, stack) => Text('Failed to load: $error', style: TextStyle(color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}
