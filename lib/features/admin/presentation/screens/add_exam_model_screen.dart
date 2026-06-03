import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_exams_provider.dart';
import '../../../courses/domain/models/exam_model.dart';
import '../../../courses/domain/models/exam_model_entity.dart';
import '../../../courses/presentation/providers/storage_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

const _kAccent = Color(0xFFEC4899);
const _kAccentDark = Color(0xFFBE185D);
const _kBorderLight = Color(0xFFE2E8F0);

/// Standalone Add / Edit Exam Model screen.
///
/// If [modelToEdit] is null → Add mode.
/// If [preselectedExam] is provided → exam picker is pre-filled and locked.
class AddExamModelScreen extends ConsumerStatefulWidget {
  final ExamModelEntity? modelToEdit;

  /// When navigating from ManageExamModelsScreen the exam is already known.
  final ExamModel? preselectedExam;

  const AddExamModelScreen({
    super.key,
    this.modelToEdit,
    this.preselectedExam,
  });

  @override
  ConsumerState<AddExamModelScreen> createState() => _AddExamModelScreenState();
}

class _AddExamModelScreenState extends ConsumerState<AddExamModelScreen> {
  final _modelNumberController = TextEditingController();
  final _titleControllers = {
    'EN': TextEditingController(),
    'FR': TextEditingController(),
    'AR': TextEditingController(),
  };
  final _examPdfController = TextEditingController();
  final _correctionPdfController = TextEditingController();

  ExamModel? _selectedExam;
  bool _isSaving = false;
  bool _uploadingExam = false;
  bool _uploadingCorrection = false;

  bool get _isEditing => widget.modelToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.preselectedExam;

    final m = widget.modelToEdit;
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
    for (final c in _titleControllers.values) c.dispose();
    _examPdfController.dispose();
    _correctionPdfController.dispose();
    super.dispose();
  }

  // ── Upload helpers ────────────────────────────────────────────

  Future<void> _pickAndUpload(
    TextEditingController target, {
    required bool isExam,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    if (mounted) setState(() => isExam ? _uploadingExam = true : _uploadingCorrection = true);

    try {
      final url = await ref.read(storageRepositoryProvider).uploadPdfBytes(bytes);
      target.text = url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => isExam ? _uploadingExam = false : _uploadingCorrection = false);
    }
  }

  // ── Save ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    final examId = _isEditing ? widget.modelToEdit!.examId : _selectedExam?.id;
    if (examId == null) {
      _snack('Please select a parent exam first.');
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(adminRepositoryProvider);
      int modelNumber = int.tryParse(_modelNumberController.text.trim()) ?? 0;

      final data = <String, dynamic>{
        'exam_id': examId,
        'title_en': _titleControllers['EN']!.text.trim(),
        'title_fr': _titleControllers['FR']!.text.trim(),
        'title_ar': _titleControllers['AR']!.text.trim(),
        'exam_pdf_url': _examPdfController.text.trim(),
        'correction_pdf_url': _correctionPdfController.text.trim(),
      };

      if (_isEditing) {
        if (modelNumber > 0) data['model_number'] = modelNumber;
        await repo.updateExamModel(widget.modelToEdit!.id, data);
      } else {
        if (modelNumber <= 0) {
          modelNumber = await repo.getNextModelNumber(examId);
        }
        data['model_number'] = modelNumber;
        await repo.addExamModel(data);
      }

      ref.invalidate(adminExamModelsProvider(examId));

      messenger.showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Model updated!' : 'Model created!'),
        backgroundColor: Colors.green.shade600,
      ));
      navigator.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      _snack('Error: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(localeProvider).languageCode;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              children: [
                // ── Parent Exam picker (locked when editing) ──
                _sectionCard(
                  isDark,
                  title: 'Parent Exam',
                  icon: Icons.assignment_rounded,
                  child: _isEditing
                      ? _fixedExamInfo(locale)
                      : _examDropdown(locale, isDark),
                ),
                const SizedBox(height: 16),

                // ── Model number ──
                _sectionCard(
                  isDark,
                  title: 'Model Number',
                  icon: Icons.format_list_numbered_rounded,
                  child: _field(
                    _modelNumberController,
                    'Auto-assigned if left empty',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Localized titles ──
                _sectionCard(
                  isDark,
                  title: 'Titles',
                  icon: Icons.translate_rounded,
                  child: Column(
                    children: [
                      _langField(isDark, 'EN', 'Title (English)', false),
                      const SizedBox(height: 12),
                      _langField(isDark, 'FR', 'Title (Français)', false),
                      const SizedBox(height: 12),
                      _langField(isDark, 'AR', 'Title (العربية)', true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── PDF uploads ──
                _sectionCard(
                  isDark,
                  title: 'PDF Files',
                  icon: Icons.picture_as_pdf_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _pdfField(
                        label: 'Exam PDF',
                        controller: _examPdfController,
                        isUploading: _uploadingExam,
                        isDark: isDark,
                        onUpload: () =>
                            _pickAndUpload(_examPdfController, isExam: true),
                      ),
                      const SizedBox(height: 16),
                      _pdfField(
                        label: 'Correction PDF',
                        controller: _correctionPdfController,
                        isUploading: _uploadingCorrection,
                        isDark: isDark,
                        onUpload: () =>
                            _pickAndUpload(_correctionPdfController, isExam: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Submit ──
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isEditing ? 'Update Model' : 'Create Model',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Exam selector ─────────────────────────────────────────────

  Widget _examDropdown(String locale, bool isDark) {
    final examsAsync = ref.watch(allExamsForSelectorProvider);
    return examsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text('Failed to load exams: $e', style: const TextStyle(color: Colors.red)),
      data: (exams) {
        final safeValue =
            exams.any((e) => e.id == _selectedExam?.id) ? _selectedExam?.id : null;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : _kBorderLight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonFormField<String>(
            value: safeValue,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Select parent exam',
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            items: exams.map((exam) {
              final title = exam.getTitle(locale).isNotEmpty
                  ? exam.getTitle(locale)
                  : 'Exam ${exam.orderNumber} · S${exam.semester}';
              return DropdownMenuItem(value: exam.id, child: Text(title));
            }).toList(),
            onChanged: (id) {
              setState(() {
                _selectedExam = exams.firstWhere((e) => e.id == id);
              });
            },
          ),
        );
      },
    );
  }

  Widget _fixedExamInfo(String locale) {
    // When editing the exam is fixed (fetched from the model itself via examId).
    // Show a read-only chip using the preselectedExam label if available.
    final label = widget.preselectedExam != null
        ? widget.preselectedExam!.getTitle(locale).isNotEmpty
            ? widget.preselectedExam!.getTitle(locale)
            : 'Exam ${widget.preselectedExam!.orderNumber}'
        : 'Exam (id: ${widget.modelToEdit!.examId})';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: _kAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Icon(Icons.lock_rounded, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // ── Shared widget builders ─────────────────────────────────────

  Widget _sectionCard(
    bool isDark, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : _kBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _kAccent),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _langField(bool isDark, String key, String hint, bool isRtl) {
    return _field(
      _titleControllers[key]!,
      hint,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool isRtl = false,
    TextInputType? keyboardType,
    bool isDark = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: isRtl ? TextDirection.rtl : null,
      textAlign: isRtl ? TextAlign.right : TextAlign.start,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
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

  Widget _pdfField({
    required String label,
    required TextEditingController controller,
    required bool isUploading,
    required bool isDark,
    required VoidCallback onUpload,
  }) {
    final hasUrl = controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _kAccent)),
            if (hasUrl) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 16),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _field(controller, '$label URL or storage path', isDark: isDark),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onUpload,
          icon: isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent))
              : const Icon(Icons.upload_file_rounded, size: 18, color: _kAccent),
          label: Text(
            isUploading ? 'Uploading...' : 'Upload $label',
            style: const TextStyle(color: _kAccent, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kBorderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            child: Text(
              _isEditing ? 'Edit Model' : 'Add Exam Model',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
