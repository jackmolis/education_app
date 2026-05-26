import 'package:flutter/material.dart';
import '../../../../core/widgets/tap_scale_wrapper.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (hasPdf)
            Expanded(
              child: _PremiumActionCard(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                gradient: const [Color(0xFFFF6B35), Color(0xFFFF8F65)],
                isDark: isDark,
                onTap: onOpenPdf,
              ),
            ),
          if (hasPdf) const SizedBox(width: 10),
          Expanded(
            child: _PremiumActionCard(
              icon: isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              label: isCompleted ? loc.done : loc.markComplete,
              gradient: isCompleted
                  ? const [Color(0xFF10B981), Color(0xFF34D399)]
                  : const [Color(0xFF4A6CF7), Color(0xFF819DF9)],
              isDark: isDark,
              isLoading: isMarkingComplete,
              onTap: isCompleted || isMarkingComplete ? null : onMarkComplete,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PremiumActionCard(
              icon: Icons.note_alt_rounded,
              label: loc.notes,
              gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
              isDark: isDark,
              onTap: onNotes,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final bool isDark;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PremiumActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.isDark,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null && !isLoading;

    return TapScaleWrapper(
      onTap: () => onTap?.call(),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
