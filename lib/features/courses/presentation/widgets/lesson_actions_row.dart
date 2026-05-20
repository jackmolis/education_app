import 'package:flutter/material.dart';
import '../../../../core/widgets/tap_scale_wrapper.dart';

class LessonActionsRow extends StatelessWidget {
  final VoidCallback? onOpenPdf;
  final VoidCallback onMarkComplete;
  final VoidCallback onNotes;
  final bool isCompleted;
  final bool isMarkingComplete;
  final bool hasPdf;

  const LessonActionsRow({
    super.key,
    this.onOpenPdf,
    required this.onMarkComplete,
    required this.onNotes,
    this.isCompleted = false,
    this.isMarkingComplete = false,
    this.hasPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (hasPdf)
            Expanded(
              child: _ActionButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                color: const Color(0xFFF97316),
                isDark: isDark,
                onTap: onOpenPdf,
              ),
            ),
          if (hasPdf) const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              label: isCompleted ? 'Done' : 'Complete',
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFF4A6CF7),
              isDark: isDark,
              isLoading: isMarkingComplete,
              onTap: isCompleted || isMarkingComplete
                  ? null
                  : onMarkComplete,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.note_alt_outlined,
              label: 'Notes',
              color: const Color(0xFF7C3AED),
              isDark: isDark,
              onTap: onNotes,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScaleWrapper(
      onTap: () => onTap?.call(),
      child: Opacity(
        opacity: onTap == null && !isLoading ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
