import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import '../../data/admin_providers.dart';
import '../providers/admin_assignments_provider.dart';
import '../widgets/subject_category_selector.dart';
import '../../../courses/domain/models/home_assignment_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../../core/providers/locale_provider.dart';

const _kAccentA = Color(0xFF6366F1);
const _kAccentADark = Color(0xFF4338CA);
const _kBorderLightA = Color(0xFFE2E8F0);

class ManageAssignmentsScreen extends ConsumerStatefulWidget {
  const ManageAssignmentsScreen({super.key});

  @override
  ConsumerState<ManageAssignmentsScreen> createState() =>
      _ManageAssignmentsScreenState();
}

class _ManageAssignmentsScreenState
    extends ConsumerState<ManageAssignmentsScreen> {
  String? _selectedSubjectId;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(localeProvider).languageCode;
    final subjectsAsync = ref.watch(subjectsProvider);

    final filter = (subjectId: _selectedSubjectId);
    final assignmentsAsync = ref.watch(adminAssignmentsProvider(filter));

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isDark),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
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
                        hintText: 'Search assignments...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: _kAccentA),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: _kBorderLightA)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: _kBorderLightA)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _kAccentA, width: 1.5)),
                      ),
                    ),
                  ),

                  // Subject filter
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
                                : _kBorderLightA),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.layers_rounded,
                                  size: 18, color: _kAccentA),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Filter by Subject',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ),
                              if (_selectedSubjectId != null)
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedSubjectId = null),
                                  child: const Text('Clear',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _kAccentA)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SubjectCategorySelector(
                            onSubjectSelected: (subject, levelId) =>
                                setState(() => _selectedSubjectId = subject.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // List
                  assignmentsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: _kAccentA)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: EmptyStateWidget(
                        icon: Icons.error_outline,
                        title: 'Failed to load assignments',
                        actionLabel: 'Try Again',
                        onAction: () =>
                            ref.invalidate(adminAssignmentsProvider(filter)),
                      ),
                    ),
                    data: (items) {
                      final filtered = _search.isEmpty
                          ? items
                          : items.where((a) {
                              final t =
                                  '${a.titleEn ?? ''} ${a.titleFr ?? ''} ${a.titleAr ?? ''}'
                                      .toLowerCase();
                              return t.contains(_search);
                            }).toList();

                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: EmptyStateWidget(
                            icon: Icons.home_work_outlined,
                            title: 'No assignments',
                            subtitle: 'Add one using the + button.',
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final a = filtered[index];
                          final subjectName =
                              _subjectName(subjectsAsync, a.subjectId, locale);
                          return _AssignmentAdminCard(
                            title: a.getTitle(locale).isNotEmpty
                                ? a.getTitle(locale)
                                : 'Assignment ${a.orderNumber}',
                            subtitle: subjectName,
                            onViewSubmissions: () => context.push(
                                '/admin/manage-assignments/${a.id}/submissions'),
                            onEdit: () => context
                                .push('/admin/add-assignment', extra: a),
                            onDelete: () =>
                                _confirmDelete(context, a, filter),
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
        backgroundColor: _kAccentA,
        onPressed: () => context.push('/admin/add-assignment'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Assignment',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _subjectName(AsyncValue<List<SubjectModel>> subjectsAsync,
      String subjectId, String locale) {
    return subjectsAsync.maybeWhen(
      data: (subjects) {
        final match = subjects.where((s) => s.id == subjectId);
        return match.isNotEmpty ? match.first.getName(locale) : 'Subject';
      },
      orElse: () => 'Subject',
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      HomeAssignmentModel assignment, AdminAssignmentsFilter filter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
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
      await ref.read(adminRepositoryProvider).deleteHomeAssignment(assignment.id);
      ref.invalidate(adminAssignmentsProvider(filter));
      messenger
          .showSnackBar(const SnackBar(content: Text('Assignment deleted.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
          const Expanded(
            child: Text('Manage Assignments',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ),
          const Icon(Icons.home_work_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _AssignmentAdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onViewSubmissions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentAdminCard({
    required this.title,
    required this.subtitle,
    required this.onViewSubmissions,
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
                  : _kBorderLightA),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _kAccentA.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_work_rounded, color: _kAccentA),
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
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_rounded,
                  size: 20, color: Color(0xFF10B981)),
              onPressed: onViewSubmissions,
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
}
