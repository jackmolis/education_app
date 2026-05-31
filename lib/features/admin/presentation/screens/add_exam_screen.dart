import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_exams_provider.dart';
import '../widgets/subject_category_selector.dart';
import '../../../courses/domain/models/exam_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

const _kAccent = Color(0xFFEC4899);
const _kAccentDark = Color(0xFFBE185D);
const _kBorderLight = Color(0xFFE2E8F0);

class AddExamScreen extends ConsumerStatefulWidget {
  /// When editing, the exam is supplied and the categorization selector is
  /// pre-filled with its subject (subject is fixed for an existing exam).
  final ExamModel? examToEdit;

  /// Optional subject for edit pre-fill (so we can show the subject name).
  final SubjectModel? subject;

  const AddExamScreen({super.key, this.examToEdit, this.subject});

  @override
  ConsumerState<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends ConsumerState<AddExamScreen> {
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
  final _orderController = TextEditingController();

  SubjectModel? _selectedSubject;
  String? _selectedLevelId;
  int _semester = 1;
  bool _isSaving = false;

  bool get _isEditing => widget.examToEdit != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.examToEdit;
    if (exam != null) {
      _titleControllers['EN']!.text = exam.titleEn ?? '';
      _titleControllers['FR']!.text = exam.titleFr ?? '';
      _titleControllers['AR']!.text = exam.titleAr ?? '';
      _descControllers['EN']!.text = exam.descriptionEn ?? '';
      _descControllers['FR']!.text = exam.descriptionFr ?? '';
      _descControllers['AR']!.text = exam.descriptionAr ?? '';
      _orderController.text = exam.orderNumber.toString();
      _semester = exam.semester == 2 ? 2 : 1;
      _selectedSubject = widget.subject;
    }
  }

  @override
  void dispose() {
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _descControllers.values) {
      c.dispose();
    }
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subjectId = _isEditing ? widget.examToEdit!.subjectId : _selectedSubject?.id;
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
    final router = GoRouter.of(context);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = <String, dynamic>{
        'subject_id': subjectId,
        'semester': _semester,
        'title_en': _titleControllers['EN']!.text.trim(),
        'title_fr': _titleControllers['FR']!.text.trim(),
        'title_ar': _titleControllers['AR']!.text.trim(),
        'description_en': _descControllers['EN']!.text.trim(),
        'description_fr': _descControllers['FR']!.text.trim(),
        'description_ar': _descControllers['AR']!.text.trim(),
      };

      final orderText = _orderController.text.trim();
      if (_isEditing) {
        if (orderText.isNotEmpty) {
          data['order_number'] = int.tryParse(orderText) ?? widget.examToEdit!.orderNumber;
        }
        await repo.updateExam(widget.examToEdit!.id, data);
        ref.invalidate(adminExamsProvider);
        messenger.showSnackBar(SnackBar(
          content: const Text('Exam updated!'),
          backgroundColor: Colors.green.shade600,
        ));
        navigator.pop();
      } else {
        data['order_number'] = orderText.isNotEmpty
            ? (int.tryParse(orderText) ??
                await repo.getNextExamOrderNumber(subjectId, _semester))
            : await repo.getNextExamOrderNumber(subjectId, _semester);
        final created = await repo.addExamReturning(data);
        ref.invalidate(adminExamsProvider);
        messenger.showSnackBar(SnackBar(
          content: const Text('Exam created! Add its models next.'),
          backgroundColor: Colors.green.shade600,
        ));
        // Automatically open the Manage Exam Models screen for the new exam.
        navigator.pop();
        if (created != null) {
          router.push('/admin/exam-models', extra: ExamModel.fromJson(created));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _snack('Error: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
                // ── Categorization (reuses Add Lesson hierarchy) ──
                _sectionCard(
                  isDark,
                  title: 'Categorization',
                  icon: Icons.layers_rounded,
                  child: _isEditing
                      ? _fixedSubjectInfo(locale)
                      : SubjectCategorySelector(
                          onSubjectSelected: (subject, levelId) {
                            setState(() {
                              _selectedSubject = subject;
                              _selectedLevelId = levelId;
                            });
                          },
                        ),
                ),
                const SizedBox(height: 16),

                // ── Exam Information ──
                _sectionCard(
                  isDark,
                  title: 'Exam Information',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Semester'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _semesterChip(1, 'Semester 1', isDark),
                          const SizedBox(width: 12),
                          _semesterChip(2, 'Semester 2', isDark),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _label('Order Number (optional)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _orderController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Auto if left empty'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Localization ──
                _sectionCard(
                  isDark,
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
                  ),
                ),
                const SizedBox(height: 28),

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
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isEditing ? 'Update Exam' : 'Create Exam & Add Models',
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

  Widget _fixedSubjectInfo(String locale) {
    final name = _selectedSubject?.getName(locale) ?? 'Subject';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.library_books_rounded, color: _kAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _langBlock(bool isDark, String key, String label, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : _kBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: _kAccent)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleControllers[key]!,
            textDirection: isRtl ? TextDirection.rtl : null,
            textAlign: isRtl ? TextAlign.right : TextAlign.start,
            decoration: _inputDecoration(isRtl ? 'عنوان الفرض' : 'Exam title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descControllers[key]!,
            textDirection: isRtl ? TextDirection.rtl : null,
            textAlign: isRtl ? TextAlign.right : TextAlign.start,
            maxLines: 3,
            decoration: _inputDecoration(isRtl ? 'وصف الفرض' : 'Description'),
          ),
        ],
      ),
    );
  }

  Widget _semesterChip(int value, String label, bool isDark) {
    final isActive = _semester == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _semester = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [_kAccent, _kAccentDark])
                : null,
            color: isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: isActive ? null : Border.all(color: _kBorderLight),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  Widget _sectionCard(bool isDark,
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : _kBorderLight),
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorderLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

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
              _isEditing ? 'Edit Exam' : 'Add Exam',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.assignment_add, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}
