import 'package:flutter/material.dart';

class LessonActionButtons extends StatefulWidget {
  final bool isCompleted;
  final bool isMarkingAsComplete;
  final bool hasPdf;
  final VoidCallback? onMarkComplete;
  final VoidCallback onStartQuiz;
  final VoidCallback onViewPdf;

  const LessonActionButtons({
    super.key,
    required this.isCompleted,
    required this.isMarkingAsComplete,
    required this.hasPdf,
    required this.onMarkComplete,
    required this.onStartQuiz,
    required this.onViewPdf,
  });

  @override
  State<LessonActionButtons> createState() => _LessonActionButtonsState();
}

class _LessonActionButtonsState extends State<LessonActionButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTapDown: widget.onMarkComplete == null ? null : (_) => _scaleController.forward(),
      onTapUp: widget.onMarkComplete == null
          ? null
          : (_) {
              _scaleController.reverse();
              widget.onMarkComplete?.call();
            },
      onTapCancel: widget.onMarkComplete == null ? null : () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.isCompleted
                ? const LinearGradient(
                    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)])
                : const LinearGradient(
                    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (widget.isCompleted
                        ? const Color(0xFF00B4DB)
                        : const Color(0xFF4A00E0))
                    .withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: widget.isMarkingAsComplete
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isCompleted ? 'Completed' : 'Mark as Complete',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPrimaryButton(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: widget.onStartQuiz,
          icon: const Icon(Icons.quiz_rounded),
          label: const Text('Start Quiz'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.hasPdf) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onViewPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
            label: const Text('View PDF Notes'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.grey.shade700,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
