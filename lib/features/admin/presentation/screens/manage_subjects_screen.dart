import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../streams/presentation/providers/streams_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

const _kAccent = Color(0xFF7C3AED);
const _kAccentDark = Color(0xFF5B21B6);
const _kBorderLight = Color(0xFFE2E8F0);

class ManageSubjectsScreen extends ConsumerStatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  ConsumerState<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends ConsumerState<ManageSubjectsScreen> {
  String? _selectedLevelId;
  String? _selectedStreamId;
  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: _buildFab(context),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader(context, theme, isDark)),

          // Level Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _buildLevelSelector(theme, isDark),
            ),
          ),

          // Stream Selection (if level has streams)
          if (_selectedLevelId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildStreamSelector(theme, isDark),
              ),
            ),

          // Option Selection (if level/stream has options)
          if (_selectedLevelId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildOptionSelector(theme, isDark),
              ),
            ),

          // Subjects List
          if (_selectedLevelId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildSubjectsList(theme, isDark),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildSelectLevelPrompt(theme),
            ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1B69), const Color(0xFF1A1145)]
              : [_kAccent, _kAccentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Subjects',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a level to view and manage subjects',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.category_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEVEL SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLevelSelector(ThemeData theme, bool isDark) {
    final levelsAsync = ref.watch(levelsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(theme, 'Educational Level', Icons.school_rounded),
        const SizedBox(height: 10),
        levelsAsync.when(
          loading: () => _chipShimmer(isDark),
          error: (e, _) => Text('Error: $e', style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
          data: (levels) {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: levels.map((level) {
                final isActive = _selectedLevelId == level.id;
                return _buildChip(
                  label: level.name,
                  isActive: isActive,
                  isDark: isDark,
                  theme: theme,
                  onTap: () {
                    setState(() {
                      _selectedLevelId = isActive ? null : level.id;
                      _selectedStreamId = null;
                      _selectedOption = null;
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STREAM SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStreamSelector(ThemeData theme, bool isDark) {
    final streamsAsync = ref.watch(streamsByLevelProvider(_selectedLevelId!));
    final locale = ref.watch(localeProvider);

    return streamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        if (streams.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Stream / Branch', Icons.account_tree_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildChip(
                  label: 'All Streams',
                  isActive: _selectedStreamId == null,
                  isDark: isDark,
                  theme: theme,
                  onTap: () => setState(() {
                    _selectedStreamId = null;
                    _selectedOption = null;
                  }),
                ),
                ...streams.map((stream) {
                  final isActive = _selectedStreamId == stream.id;
                  return _buildChip(
                    label: stream.getName(locale.languageCode),
                    isActive: isActive,
                    isDark: isDark,
                    theme: theme,
                    onTap: () => setState(() {
                      _selectedStreamId = isActive ? null : stream.id;
                      _selectedOption = null;
                    }),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OPTION SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOptionSelector(ThemeData theme, bool isDark) {
    final optionsAsync = ref.watch(
      optionsByLevelProvider((levelId: _selectedLevelId!, streamId: _selectedStreamId)),
    );

    return optionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (options) {
        if (options.isEmpty || options.length <= 1) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Language Option', Icons.translate_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildChip(
                  label: 'All Options',
                  isActive: _selectedOption == null,
                  isDark: isDark,
                  theme: theme,
                  onTap: () => setState(() => _selectedOption = null),
                ),
                ...options.map((opt) {
                  final isActive = _selectedOption == opt;
                  final label = opt == 'ar' ? 'Arabic Option' : (opt == 'fr' ? 'French Option' : opt.toUpperCase());
                  return _buildChip(
                    label: label,
                    isActive: isActive,
                    isDark: isDark,
                    theme: theme,
                    onTap: () => setState(() => _selectedOption = isActive ? null : opt),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBJECTS LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSubjectsList(ThemeData theme, bool isDark) {
    final subjectsAsync = ref.watch(subjectsByLevelProvider(
      (levelId: _selectedLevelId!, streamId: _selectedStreamId, optionLang: _selectedOption),
    ));
    final locale = ref.watch(localeProvider);

    return subjectsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _kAccent)),
      ),
      error: (e, _) => _buildErrorState(theme, e.toString()),
      data: (subjects) {
        if (subjects.isEmpty) return _buildEmptySubjects(theme, isDark);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionLabel(theme, 'Subjects', Icons.menu_book_rounded),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${subjects.length} found',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...subjects.asMap().entries.map((entry) {
              final index = entry.key;
              final subject = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < subjects.length - 1 ? 12 : 0),
                child: _SubjectCard(
                  subject: subject,
                  locale: locale.languageCode,
                  isDark: isDark,
                  theme: theme,
                  onEdit: () => _showEditDialog(context, ref, subject),
                  onDelete: () => _showDeleteDialog(context, ref, subject),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kAccent),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isActive,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [_kAccent, _kAccentDark]) : null,
          color: isActive ? null : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? null
              : Border.all(color: isDark ? Colors.white.withOpacity(0.1) : _kBorderLight),
          boxShadow: isActive
              ? [BoxShadow(color: _kAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _chipShimmer(bool isDark) {
    return Row(
      children: List.generate(3, (_) => Container(
        width: 80,
        height: 38,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildSelectLevelPrompt(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'Select a level to manage subjects',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose an educational level above to view its subjects',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubjects(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 14),
          Text(
            'No subjects found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a subject to this level to get started',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 36, color: theme.colorScheme.error),
          const SizedBox(height: 10),
          Text('Failed to load subjects', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.error)),
          const SizedBox(height: 4),
          Text(error, style: TextStyle(fontSize: 12, color: theme.colorScheme.onErrorContainer.withOpacity(0.7)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/add-subject'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, _kAccentDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Add Subject', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showDeleteDialog(BuildContext context, WidgetRef ref, SubjectModel subject) {
    final locale = Localizations.localeOf(context).languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.getName(locale)}"?\n\nThis action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(adminRepositoryProvider).deleteSubject(subject.id);
                ref.read(coursesRepositoryProvider).clearSubjectsCache();
                ref.invalidate(subjectsByLevelProvider(
                  (levelId: _selectedLevelId!, streamId: _selectedStreamId, optionLang: _selectedOption),
                ));
                scaffoldMessenger.showSnackBar(SnackBar(
                  content: const Text('Subject deleted successfully.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green.shade600,
                ));
              } catch (e) {
                String errorMsg = e.toString();
                if (errorMsg.contains('foreign key constraint') || errorMsg.contains('23503')) {
                  errorMsg = 'Cannot delete: subject contains lessons or quizzes.';
                }
                scaffoldMessenger.showSnackBar(SnackBar(
                  content: Text('Failed: $errorMsg'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, SubjectModel subject) {
    final nameEnController = TextEditingController(text: subject.nameEn);
    final nameFrController = TextEditingController(text: subject.nameFr);
    final nameArController = TextEditingController(text: subject.nameAr);
    final descController = TextEditingController(text: subject.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Subject'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameEnController,
                        decoration: InputDecoration(
                          labelText: 'English Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: nameFrController,
                        decoration: InputDecoration(
                          labelText: 'French Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: nameArController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'Arabic Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          suffixIcon: const Icon(Icons.edit_rounded, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(adminRepositoryProvider).updateSubject(subject.id, {
                              'name_en': nameEnController.text.trim(),
                              'name_fr': nameFrController.text.trim(),
                              'name_ar': nameArController.text.trim(),
                              'description': descController.text.trim(),
                            });
                            ref.read(coursesRepositoryProvider).clearSubjectsCache();
                            ref.invalidate(subjectsByLevelProvider(
                              (levelId: _selectedLevelId!, streamId: _selectedStreamId, optionLang: _selectedOption),
                            ));
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            scaffoldMessenger.showSnackBar(SnackBar(
                              content: const Text('Subject updated successfully.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.green.shade600,
                            ));
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            scaffoldMessenger.showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ));
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// _SubjectCard — Modern subject management card
// ═══════════════════════════════════════════════════════════════

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final String locale;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.locale,
    required this.isDark,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  static const _gradients = <List<Color>>[
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    [Color(0xFFFF6B35), Color(0xFFFF8F65)],
    [Color(0xFF10B981), Color(0xFF34D399)],
    [Color(0xFFEC4899), Color(0xFFF9A8D4)],
    [Color(0xFFF59E0B), Color(0xFFFCD34D)],
  ];

  @override
  Widget build(BuildContext context) {
    final name = subject.getName(locale);
    final colorIndex = name.hashCode.abs() % _gradients.length;
    final gradient = _gradients[colorIndex];
    final hasImage = (subject.imageUrl ?? '').isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Image / Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: hasImage ? null : LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              image: hasImage
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(subject.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 24)),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((subject.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subject.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          _ActionButton(
            icon: Icons.edit_rounded,
            color: _kAccent,
            isDark: isDark,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
            isDark: isDark,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
