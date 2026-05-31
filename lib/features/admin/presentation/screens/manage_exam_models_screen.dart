import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_exams_provider.dart';
import '../../../courses/domain/models/exam_model.dart';
import '../../../courses/domain/models/exam_model_entity.dart';
import '../../../courses/presentation/providers/storage_provider.dart';
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
                      onEdit: () => _openForm(context, ref, model),
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
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Model', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, ExamModelEntity? model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamModelFormSheet(examId: exam.id, model: model),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      messenger.showSnackBar(const SnackBar(content: Text('Model deleted.')));
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
              color: isDark ? Colors.white.withValues(alpha: 0.08) : _kBorderLight),
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
                      _pill('Correction', hasCorrection, const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF0EA5E9)),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
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
        color: active ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
              size: 12, color: active ? color : Colors.grey),
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

// ══════════════════════════════════════════════════════════════
// Add / Edit Exam Model form (bottom sheet)
// ══════════════════════════════════════════════════════════════

class _ExamModelFormSheet extends ConsumerStatefulWidget {
  final String examId;
  final ExamModelEntity? model;

  const _ExamModelFormSheet({required this.examId, this.model});

  @override
  ConsumerState<_ExamModelFormSheet> createState() => _ExamModelFormSheetState();
}

class _ExamModelFormSheetState extends ConsumerState<_ExamModelFormSheet> {
  final _modelNumberController = TextEditingController();
  final _titleControllers = {
    'EN': TextEditingController(),
    'FR': TextEditingController(),
    'AR': TextEditingController(),
  };
  final _examPdfController = TextEditingController();
  final _correctionPdfController = TextEditingController();
  bool _isSaving = false;
  bool _uploadingExam = false;
  bool _uploadingCorrection = false;

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    if (m != null) {
      _modelNumberController.text = m.modelNumber.toString();
      _titleControllers['EN']!.text = m.titleEn ?? '';
      _titleControllers['FR']!.text = m.titleFr ?? '';
      _titleControllers['AR']!.text = m.titleAr ?? '';
      _examPdfController.text = m.examPdfUrl;
      _correctionPdfController.text = m.correctionPdfUrl;
    }
  }

  @override
  void dispose() {
    _modelNumberController.dispose();
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    _examPdfController.dispose();
    _correctionPdfController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(adminRepositoryProvider);
      int modelNumber = int.tryParse(_modelNumberController.text.trim()) ?? 0;

      final data = <String, dynamic>{
        'exam_id': widget.examId,
        'title_en': _titleControllers['EN']!.text.trim(),
        'title_fr': _titleControllers['FR']!.text.trim(),
        'title_ar': _titleControllers['AR']!.text.trim(),
        'exam_pdf_url': _examPdfController.text.trim(),
        'correction_pdf_url': _correctionPdfController.text.trim(),
      };

      if (widget.model != null) {
        if (modelNumber > 0) data['model_number'] = modelNumber;
        await repo.updateExamModel(widget.model!.id, data);
      } else {
        if (modelNumber <= 0) {
          modelNumber = await repo.getNextModelNumber(widget.examId);
        }
        data['model_number'] = modelNumber;
        await repo.addExamModel(data);
      }

      ref.invalidate(adminExamModelsProvider(widget.examId));
      messenger.showSnackBar(SnackBar(
        content: Text(widget.model != null ? 'Model updated!' : 'Model created!'),
        backgroundColor: Colors.green.shade600,
      ));
      navigator.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.model != null ? 'Edit Model' : 'Add Model',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _field(_modelNumberController, 'Model number',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(_titleControllers['EN']!, 'Title (English)'),
              const SizedBox(height: 12),
              _field(_titleControllers['FR']!, 'Title (Français)'),
              const SizedBox(height: 12),
              _field(_titleControllers['AR']!, 'Title (العربية)', isRtl: true),
              const SizedBox(height: 12),
              _pdfField(
                label: 'Exam PDF',
                controller: _examPdfController,
                isUploading: _uploadingExam,
                onUpload: () => _pickAndUpload(_examPdfController, isExam: true),
              ),
              const SizedBox(height: 12),
              _pdfField(
                label: 'Correction PDF',
                controller: _correctionPdfController,
                isUploading: _uploadingCorrection,
                onUpload: () =>
                    _pickAndUpload(_correctionPdfController, isExam: false),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.model != null ? 'Update' : 'Create',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(TextEditingController target,
      {required bool isExam}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    setState(() {
      if (isExam) {
        _uploadingExam = true;
      } else {
        _uploadingCorrection = true;
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      // Reuse the same storage upload service used by lessons.
      final url = await ref.read(storageRepositoryProvider).uploadPdfBytes(bytes);
      target.text = url;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          if (isExam) {
            _uploadingExam = false;
          } else {
            _uploadingCorrection = false;
          }
        });
      }
    }
  }

  Widget _pdfField({
    required String label,
    required TextEditingController controller,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    final hasValue = controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(controller, '$label URL / storage path'),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file_rounded, size: 18, color: _kAccent),
              label: Text(
                isUploading ? 'Uploading...' : 'Upload $label',
                style: const TextStyle(color: _kAccent, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kBorderLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 18),
            ],
          ],
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {bool isRtl = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: isRtl ? TextDirection.rtl : null,
      textAlign: isRtl ? TextAlign.right : TextAlign.start,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
