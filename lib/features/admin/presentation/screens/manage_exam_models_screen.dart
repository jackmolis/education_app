import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_exams_provider.dart';
import '../../../courses/domain/models/exam_model.dart';
import '../../../courses/domain/models/exam_model_entity.dart';
import '../../../../core/providers/locale_provider.dart';

const _kAccent = Color(0xFFEC4899);
const _kAccentDark = Color(0xFFBE185D);
const _kBorderLight = Color(0xFFE2E8F0);

class ManageExamModelsScreen extends ConsumerWidget {
  final ExamModel exam;

  const ManageExamModelsScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider).languageCode;
    final modelsAsync = ref.watch(adminExamModelsProvider(exam.id));
    final examTitle = exam.getTitle(locale).isNotEmpty
        ? exam.getTitle(locale)
        : 'Exam ${exam.orderNumber}';

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, examTitle),
          Expanded(
            child: modelsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAccent)),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Failed to load models',
                actionLabel: 'Try Again',
                onAction: () => ref.invalidate(adminExamModelsProvider(exam.id)),
              ),
              data: (models) {
                if (models.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.folder_open_outlined,
                    title: 'No models',
                    subtitle: 'Add a model using the + button.',
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    final title = model.getTitle(locale).isNotEmpty
                        ? model.getTitle(locale)
                        : 'Model ${model.modelNumber}';
                    return _ModelAdminCard(
                      title: title,
                      hasExam: model.hasExamPdf,
                      hasCorrection: model.hasCorrectionPdf,
                      onEdit: () => _openForm(context, model),
                      onDelete: () => _confirmDelete(context, ref, model),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Model', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Navigate to the standalone Add/Edit Exam Model screen.
  /// [model] is null → Add mode; non-null → Edit mode.
  void _openForm(BuildContext context, ExamModelEntity? model) {
    context.push(
      '/admin/add-exam-model',
      extra: model == null
          ? <String, dynamic>{'exam': exam}
          : <String, dynamic>{'model': model, 'exam': exam},
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ExamModelEntity model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Model'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).deleteExamModel(model.id);
      ref.invalidate(adminExamModelsProvider(exam.id));
      messenger.showSnackBar(
          const SnackBar(content: Text('Model deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildHeader(BuildContext context, String examTitle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_kAccent, _kAccentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Models',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(examTitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

// ── Model admin card ─────────────────────────────────────────────────────────

class _ModelAdminCard extends StatelessWidget {
  final String title;
  final bool hasExam;
  final bool hasCorrection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModelAdminCard({
    required this.title,
    required this.hasExam,
    required this.hasCorrection,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _kBorderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_rounded, color: _kAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill('Exam PDF', hasExam, const Color(0xFF4A6CF7)),
                      const SizedBox(width: 6),
                      _pill('Correction', hasCorrection,
                          const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 20, color: Color(0xFF0EA5E9)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded,
                  size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.check_circle_rounded
                : Icons.remove_circle_outline_rounded,
            size: 12,
            color: active ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? color : Colors.grey)),
        ],
      ),
    );
  }
}
