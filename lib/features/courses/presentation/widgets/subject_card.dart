import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/tap_scale_wrapper.dart';
import '../../data/progress_repository.dart';

/// Maps subject name to a meaningful icon.
IconData subjectIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('math') || lower.contains('رياضيات')) return Icons.square_foot_rounded;
  if (lower.contains('phys') || lower.contains('فيزياء')) return Icons.blur_circular_rounded;
  if (lower.contains('svt') || lower.contains('bio') || lower.contains('علوم')) return Icons.biotech_rounded;
  if (lower.contains('comput') || lower.contains('info') || lower.contains('حاسوب')) return Icons.desktop_mac_rounded;
  if (lower.contains('chem') || lower.contains('كيمياء')) return Icons.science_rounded;
  if (lower.contains('hist') || lower.contains('تاريخ')) return Icons.history_edu_rounded;
  if (lower.contains('lang') || lower.contains('english') || lower.contains('french') || lower.contains('arab')) return Icons.translate_rounded;
  if (lower.contains('art') || lower.contains('فن')) return Icons.palette_rounded;
  return Icons.menu_book_rounded;
}

/// Color palette for subject cards — cycles through indices.
const _gradients = [
  [Color(0xFF4A6CF7), Color(0xFF7C3AED)],
  [Color(0xFF10B981), Color(0xFF06B6D4)],
  [Color(0xFFFF8A00), Color(0xFFEF4444)],
  [Color(0xFF7C3AED), Color(0xFFEC4899)],
  [Color(0xFF06B6D4), Color(0xFF4A6CF7)],
  [Color(0xFFF59E0B), Color(0xFFFF8A00)],
  [Color(0xFFEF4444), Color(0xFF7C3AED)],
  [Color(0xFF10B981), Color(0xFF4A6CF7)],
];

/// Premium SaaS-style subject card with gradient, icon, progress bar, and tap animation.
class SubjectCard extends ConsumerWidget {
  const SubjectCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.onTap,
    this.colorIndex = 0,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final VoidCallback onTap;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(subjectProgressProvider(id));
    final colors = _gradients[colorIndex % _gradients.length];

    return TapScaleWrapper(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background watermark icon
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                subjectIcon(name),
                size: 80,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      subjectIcon(name),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  // Subject name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Animated gradient progress bar
                  progressAsync.when(
                    data: (progress) => _GradientProgressBar(progress: progress),
                    loading: () => const _GradientProgressBar(progress: 0),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated progress bar with gradient fill and rounded edges.
class _GradientProgressBar extends StatelessWidget {
  final double progress;
  const _GradientProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    // Track
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Fill
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFFD180)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).round()}% complete',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (progress >= 1.0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white.withValues(alpha: 0.9), size: 12),
                  const SizedBox(width: 3),
                  Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
