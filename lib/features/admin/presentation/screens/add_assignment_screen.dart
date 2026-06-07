import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_assignments_provider.dart';
import '../widgets/subject_category_selector.dart';
import '../../../courses/domain/models/home_assignment_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../courses/presentation/providers/storage_provider.dart';
import '../../../../core/providers/locale_provider.dart';

const _kAccentA = Color(0xFF6366F1);
const _kAccentADark = Color(0xFF4338CA);
const _kBorderLightA = Color(0xFFE2E8F0);

class AddAssignmentScreen extends ConsumerStatefulWidget {
  final HomeAssignmentModel? assignmentToEdit;

  const AddAssignmentScreen({super.key, this.assignmentToEdit});

  @override
  ConsumerState<AddAssignmentScreen> createState() =>
      _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends ConsumerState<AddAssignmentScreen> {
  final _titleControllers = {
    'EN': TextEditingController(),
    'FR': TextEditingController(),
    'AR': TextEditingController(),
  };
  final _descControllers = {
    'EN': TextEditingController(),
    'FR': TextEditingController(),
    'AR': TextEditingController(),
  };
  final _pdfController = TextEditingController();
  final _orderController = TextEditingController();

  SubjectModel? _selectedSubject;
  bool _isSaving = false;
  bool _uploadingPdf = false;

  bool get _isEditing => widget.assignmentToEdit != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assignmentToEdit;
    if (a != null) {
      _titleControllers['EN']!.text = a.titleEn ?? '';
      _titleControllers['FR']!.text = a.titleFr ?? '';
      _titleControllers['AR']!.text = a.titleAr ?? '';
      _descControllers['EN']!.text = a.descriptionEn ?? '';
      _descControllers['FR']!.text = a.descriptionFr ?? '';
      _descControllers['AR']!.text = a.descriptionAr ?? '';
      _pdfController.text = a.pdfUrl;
      _orderController.text = a.orderNumber.toString();
    }
  }

  @override
  void dispose() {
    for (final c in _titleControllers.values) c.dispose();
    for (final c in _descControllers.values) c.dispose();
    _pdfController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;

    if (mounted) setState(() => _uploadingPdf = true);
    try {
      final url =
          await ref.read(storageRepositoryProvider).uploadPdfBytes(bytes);
      _pdfController.text = url;
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  Future<void> _submit() async {
    final subjectId =
        _isEditing ? widget.assignmentToEdit!.subjectId : _selectedSubject?.id;
    if (subjectId == null) {
      _snack('Please select a subject first.');
      return;
    }
    if (_titleControllers['EN']!.text.trim().isEmpty &&
        _titleControllers['FR']!.text.trim().isEmpty &&
        _titleControllers['AR']!.text.trim().isEmpty) {
      _snack('Please enter a title in at least one language.');
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = <String, dynamic>{
        'subject_id': subjectId,
        'title_en': _titleControllers['EN']!.text.trim(),
        'title_fr': _titleControllers['FR']!.text.trim(),
        'title_ar': _titleControllers['AR']!.text.trim(),
        'description_en': _descControllers['EN']!.text.trim(),
        'description_fr': _descControllers['FR']!.text.trim(),
        'description_ar': _descControllers['AR']!.text.trim(),
        'pdf_url': _pdfController.text.trim(),
      };

      final orderText = _orderController.text.trim();
      if (_isEditing) {
        if (orderText.isNotEmpty)
          data['order_number'] = int.tryParse(orderText) ??
              widget.assignmentToEdit!.orderNumber;
        await repo.updateHomeAssignment(widget.assignmentToEdit!.id, data);
        ref.invalidate(adminAssignmentsProvider);
        messenger.showSnackBar(SnackBar(
            content: const Text('Assignment updated!'),
            backgroundColor: Colors.green.shade600));
        navigator.pop();
      } else {
        data['order_number'] = orderText.isNotEmpty
            ? (int.tryParse(orderText) ??
                await repo.getNextAssignmentOrderNumber(subjectId))
            : await repo.getNextAssignmentOrderNumber(subjectId);
        await repo.addHomeAssignment(data);
        ref.invalidate(adminAssignmentsProvider);
        messenger.showSnackBar(SnackBar(
            content: const Text('Assignment created!'),
            backgroundColor: Colors.green.shade600));
        navigator.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _snack('Error: $e');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // Subject
                _card(isDark,
                    title: 'Subject',
                    icon: Icons.layers_rounded,
                    child: _isEditing
                        ? _lockedSubject(locale)
                        : SubjectCategorySelector(
                            onSubjectSelected: (s, lid) =>
                                setState(() => _selectedSubject = s),
                          )),
                const SizedBox(height: 16),

                // Order
                _card(isDark,
                    title: 'Order Number (optional)',
                    icon: Icons.format_list_numbered_rounded,
                    child: _textField(_orderController, 'Auto if left empty',
                        keyboardType: TextInputType.number, isDark: isDark)),
                const SizedBox(height: 16),

                // Localization
                _card(isDark,
                    title: 'Localization',
                    icon: Icons.translate_rounded,
                    child: Column(
                      children: [
                        _langBlock(isDark, 'EN', 'English', false),
                        const SizedBox(height: 14),
                        _langBlock(isDark, 'FR', 'Français', false),
                        const SizedBox(height: 14),
                        _langBlock(isDark, 'AR', 'العربية', true),
                      ],
                    )),
                const SizedBox(height: 16),

                // PDF
                _card(isDark,
                    title: 'PDF File',
                    icon: Icons.picture_as_pdf_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text('Assignment PDF',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kAccentA)),
                            if (_pdfController.text.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF10B981), size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        _textField(_pdfController, 'PDF URL or storage path',
                            isDark: isDark),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _uploadingPdf ? null : _pickAndUpload,
                          icon: _uploadingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _kAccentA))
                              : const Icon(Icons.upload_file_rounded,
                                  size: 18, color: _kAccentA),
                          label: Text(
                            _uploadingPdf
                                ? 'Uploading...'
                                : 'Upload PDF',
                            style: const TextStyle(
                                color: _kAccentA, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorderLightA),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 28),

                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccentA,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isEditing
                                ? 'Update Assignment'
                                : 'Create Assignment',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
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

  Widget _lockedSubject(String locale) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccentA.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccentA.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.library_books_rounded, color: _kAccentA, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.assignmentToEdit!.subjectId,
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.lock_rounded, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _langBlock(bool isDark, String key, String label, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : _kBorderLightA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kAccentA)),
          const SizedBox(height: 12),
          _textField(_titleControllers[key]!,
              isRtl ? 'عنوان الفرض المنزلي' : 'Assignment title',
              isRtl: isRtl, isDark: isDark),
          const SizedBox(height: 10),
          _textField(_descControllers[key]!,
              isRtl ? 'وصف الفرض المنزلي' : 'Description',
              isRtl: isRtl, isDark: isDark, maxLines: 3),
        ],
      ),
    );
  }

  Widget _card(bool isDark,
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : _kBorderLightA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kAccentA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: _kAccentA),
            ),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    bool isRtl = false,
    TextInputType? keyboardType,
    bool isDark = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: isRtl ? TextDirection.rtl : null,
      textAlign: isRtl ? TextAlign.right : TextAlign.start,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorderLightA)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccentA, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_kAccentA, _kAccentADark],
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
              _isEditing ? 'Edit Assignment' : 'Add Assignment',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.home_work_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
