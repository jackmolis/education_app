import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_exams_provider.dart';
import '../widgets/subject_category_selector.dart';
import '../../../courses/domain/models/exam_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../../core/providers/locale_provider.dart';

const _kAccent = Color(0xFFEC4899);
const _kBorderLight = Color(0xFFE2E8F0);

class ManageExamsScreen extends ConsumerStatefulWidget {
  const ManageExamsScreen({super.key});

  @override
  ConsumerState<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends ConsumerState<ManageExamsScreen> {
  String? _selectedSubjectId;
  int? _selectedSemester;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(localeProvider).languageCode;
    final subjectsAsync = ref.watch(subjectsProvider);

    final filter = (subjectId: _selectedSubjectId, semester: _selectedSemester);
    final examsAsync = ref.watch(adminExamsProvider(filter));

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed header (back button always visible).
          _buildHeader(context, theme, isDark),

          // Everything below the header scrolls as one unit.
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      onChanged: (v) =>
                          setState(() => _search = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search exams...',
                        prefixIcon:
                            const Icon(Icons.search_rounded, color: _kAccent),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _kBorderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _kBorderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _kAccent, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // Hierarchical subject selector (Level → Stream → Option → Subject)
                  // Reuses the SAME providers as Add Lesson / Add Exam via
                  // SubjectCategorySelector — no duplicated filtering logic.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : _kBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.layers_rounded,
                                  size: 18, color: _kAccent),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Filter by Subject',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ),
                              if (_selectedSubjectId != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedSubjectId = null),
                                  child: const Text('Clear',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _kAccent)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SubjectCategorySelector(
                            onSubjectSelected: (subject, levelId) {
                              setState(() => _selectedSubjectId = subject.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Semester filter chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _chip(
                          label: 'All Semesters',
                          isActive: _selectedSemester == null,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedSemester = null),
                        ),
                        _chip(
                          label: 'Semester 1',
                          isActive: _selectedSemester == 1,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedSemester = 1),
                        ),
                        _chip(
                          label: 'Semester 2',
                          isActive: _selectedSemester == 2,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedSemester = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Exam list (non-scrollable here — the outer scroll view drives it)
                  examsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                          child: CircularProgressIndicator(color: _kAccent)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyStateWidget(
                        icon: Icons.error_outline,
                        title: 'Failed to load exams',
                        actionLabel: 'Try Again',
                        onAction: () =>
                            ref.invalidate(adminExamsProvider(filter)),
                      ),
                    ),
                    data: (exams) {
                      final filtered = _search.isEmpty
                          ? exams
                          : exams.where((e) {
                              final t =
                                  '${e.titleEn ?? ''} ${e.titleFr ?? ''} ${e.titleAr ?? ''}'
                                      .toLowerCase();
                              return t.contains(_search);
                            }).toList();

                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: EmptyStateWidget(
                            icon: Icons.assignment_outlined,
                            title: 'No exams',
                            subtitle: 'Add an exam using the + button.',
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final exam = filtered[index];
                          final subjectName = _subjectName(
                              subjectsAsync, exam.subjectId, locale);
                          return _ExamAdminCard(
                            title: exam.getTitle(locale).isNotEmpty
                                ? exam.getTitle(locale)
                                : 'Exam ${exam.orderNumber}',
                            subtitle:
                                '$subjectName • Semester ${exam.semester}',
                            onTap: () => context.push('/admin/exam-models',
                                extra: exam),
                            onEdit: () =>
                                context.push('/admin/add-exam', extra: exam),
                            onDelete: () =>
                                _confirmDelete(context, exam, filter),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        onPressed: () => context.push('/admin/add-exam'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Exam', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _subjectName(
      AsyncValue<List<SubjectModel>> subjectsAsync, String subjectId, String locale) {
    return subjectsAsync.maybeWhen(
      data: (subjects) {
        final match = subjects.where((s) => s.id == subjectId);
        return match.isNotEmpty ? match.first.getName(locale) : 'Subject';
      },
      orElse: () => 'Subject',
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ExamModel exam, AdminExamsFilter filter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text(
            'This will delete the exam and all its models. This action cannot be undone.'),
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
      await ref.read(adminRepositoryProvider).deleteExam(exam.id);
      ref.invalidate(adminExamsProvider(filter));
      messenger.showSnackBar(const SnackBar(content: Text('Exam deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_kAccent, Color(0xFFBE185D)],
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
          const Expanded(
            child: Text(
              'Manage Exams',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [_kAccent, Color(0xFFBE185D)])
                : null,
            color: isActive ? null : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: isActive ? null : Border.all(color: _kBorderLight),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData get theme => Theme.of(context);
}

class _ExamAdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamAdminCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                  child: const Icon(Icons.assignment_rounded, color: _kAccent),
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
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
        ),
      ),
    );
  }
}
