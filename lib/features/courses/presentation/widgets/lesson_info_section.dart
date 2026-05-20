import 'package:flutter/material.dart';

class LessonInfoSection extends StatelessWidget {
  final String title;
  final String subjectName;
  final int? durationMinutes;
  final int orderNumber;

  const LessonInfoSection({
    super.key,
    required this.title,
    required this.subjectName,
    this.durationMinutes,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6CF7).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subjectName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A6CF7),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF1E293B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Meta row
          Row(
            children: [
              _MetaChip(
                icon: Icons.play_circle_outline_rounded,
                label: 'Lesson $orderNumber',
                isDark: isDark,
              ),
              if (durationMinutes != null && durationMinutes! > 0) ...[
                const SizedBox(width: 16),
                _MetaChip(
                  icon: Icons.access_time_rounded,
                  label: '$durationMinutes min',
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
