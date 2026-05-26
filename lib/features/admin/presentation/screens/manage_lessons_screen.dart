import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../../streams/presentation/providers/streams_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../providers/paginated_admin_lessons_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

const _kAccent = Color(0xFF7C3AED);
const _kAccentDark = Color(0xFF5B21B6);
const _kBorderLight = Color(0xFFE2E8F0);

class ManageLessonsScreen extends ConsumerStatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  ConsumerState<ManageLessonsScreen> createState() =>
      _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends ConsumerState<ManageLessonsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedLevelId;
  String? _selectedStreamId;
  String? _selectedOption;
  String? _selectedSubjectId;
  String _searchQuery = '';
  bool _isFabVisible = true;
  bool _isSavingOrder = false;
  List<LessonModel>? _optimisticLessons;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }
    if (_selectedSubjectId != null &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      final filter = AdminLessonsFilter(
        subjectId: _selectedSubjectId,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      ref.read(paginatedAdminLessonsProvider(filter).notifier).loadMore();
    }
  }

  AdminLessonsFilter get _currentFilter => AdminLessonsFilter(
        subjectId: _selectedSubjectId,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: _buildFab(context),
      body: Column(
        children: [
          _buildHeader(context, theme, isDark),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                // Filters
                SliverToBoxAdapter(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _buildFilters(theme, isDark),
                )),
                // Search (only when subject selected)
                if (_selectedSubjectId != null)
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildSearchField(theme, isDark),
                  )),
                // Lessons list
                if (_selectedSubjectId != null)
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: _buildLessonsList(theme, isDark),
                  ))
                else
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildPrompt(theme),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Lessons',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text('Filter by level and subject to manage lessons',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.video_library_rounded,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilters(ThemeData theme, bool isDark) {
    final locale = ref.watch(localeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level
        _sectionLabel(theme, 'Educational Level', Icons.school_rounded),
        const SizedBox(height: 10),
        _buildLevelChips(theme, isDark),

        // Stream (if level has streams)
        if (_selectedLevelId != null) ...[
          const SizedBox(height: 14),
          _buildStreamChips(theme, isDark, locale.languageCode),
        ],

        // Option (if level/stream has options)
        if (_selectedLevelId != null) ...[
          const SizedBox(height: 14),
          _buildOptionChips(theme, isDark),
        ],

        // Subject
        if (_selectedLevelId != null) ...[
          const SizedBox(height: 14),
          _sectionLabel(theme, 'Subject', Icons.menu_book_rounded),
          const SizedBox(height: 10),
          _buildSubjectChips(theme, isDark, locale.languageCode),
        ],
      ],
    );
  }

  Widget _buildLevelChips(ThemeData theme, bool isDark) {
    final levelsAsync = ref.watch(levelsProvider);
    return levelsAsync.when(
      loading: () => _shimmerRow(isDark),
      error: (e, _) => Text('Error: $e',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
      data: (levels) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: levels.map((level) {
          final isActive = _selectedLevelId == level.id;
          return _chip(
            label: level.name,
            isActive: isActive,
            isDark: isDark,
            theme: theme,
            onTap: () => setState(() {
              _selectedLevelId = isActive ? null : level.id;
              _selectedStreamId = null;
              _selectedOption = null;
              _selectedSubjectId = null;
              _optimisticLessons = null;
            }),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreamChips(ThemeData theme, bool isDark, String locale) {
    final streamsAsync = ref.watch(streamsByLevelProvider(_selectedLevelId!));
    return streamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        if (streams.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Stream', Icons.account_tree_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip(
                    label: 'All',
                    isActive: _selectedStreamId == null,
                    isDark: isDark,
                    theme: theme,
                    onTap: () => setState(() {
                          _selectedStreamId = null;
                          _selectedOption = null;
                          _selectedSubjectId = null;
                          _optimisticLessons = null;
                        })),
                ...streams.map((s) {
                  final isActive = _selectedStreamId == s.id;
                  return _chip(
                    label: s.getName(locale),
                    isActive: isActive,
                    isDark: isDark,
                    theme: theme,
                    onTap: () => setState(() {
                      _selectedStreamId = isActive ? null : s.id;
                      _selectedOption = null;
                      _selectedSubjectId = null;
                      _optimisticLessons = null;
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

  Widget _buildOptionChips(ThemeData theme, bool isDark) {
    final optionsAsync = ref.watch(optionsByLevelProvider(
        (levelId: _selectedLevelId!, streamId: _selectedStreamId)));
    return optionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (options) {
        if (options.isEmpty || options.length <= 1) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Option', Icons.translate_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip(
                    label: 'All',
                    isActive: _selectedOption == null,
                    isDark: isDark,
                    theme: theme,
                    onTap: () => setState(() {
                          _selectedOption = null;
                          _selectedSubjectId = null;
                          _optimisticLessons = null;
                        })),
                ...options.map((opt) {
                  final isActive = _selectedOption == opt;
                  final label = opt == 'ar'
                      ? 'Arabic'
                      : (opt == 'fr' ? 'French' : opt.toUpperCase());
                  return _chip(
                    label: label,
                    isActive: isActive,
                    isDark: isDark,
                    theme: theme,
                    onTap: () => setState(() {
                      _selectedOption = isActive ? null : opt;
                      _selectedSubjectId = null;
                      _optimisticLessons = null;
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

  Widget _buildSubjectChips(ThemeData theme, bool isDark, String locale) {
    final subjectsAsync = ref.watch(subjectsByLevelProvider((
      levelId: _selectedLevelId!,
      streamId: _selectedStreamId,
      optionLang: _selectedOption,
    )));
    return subjectsAsync.when(
      loading: () => _shimmerRow(isDark),
      error: (e, _) => Text('Error: $e',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Text('No subjects in this level',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.4)));
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: subjects.map((s) {
            final isActive = _selectedSubjectId == s.id;
            return _chip(
              label: s.getName(locale),
              isActive: isActive,
              isDark: isDark,
              theme: theme,
              onTap: () => setState(() {
                _selectedSubjectId = isActive ? null : s.id;
                _optimisticLessons = null;
              }),
            );
          }).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSearchField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
            fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search lessons by title...',
          hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.35),
              fontWeight: FontWeight.w500),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search_rounded, color: _kAccent, size: 20),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 1.5)),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LESSONS LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLessonsList(ThemeData theme, bool isDark) {
    final paginatedAsync = ref.watch(paginatedAdminLessonsProvider(_currentFilter));
    final locale = ref.watch(localeProvider).languageCode;

    return paginatedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _kAccent)),
      ),
      error: (e, _) => _buildError(theme, e.toString()),
      data: (paginatedState) {
        final lessons = paginatedState.lessons;
        if (lessons.isEmpty) return _buildEmptyLessons(theme, isDark);

        final canReorder =
            _selectedSubjectId != null && _searchQuery.isEmpty;

        if (!canReorder) {
          _optimisticLessons = null;
        } else {
          if (_optimisticLessons == null ||
              _optimisticLessons!.length != lessons.length ||
              _optimisticLessons!.any((l) => !lessons.any((f) => f.id == l.id))) {
            _optimisticLessons = List<LessonModel>.from(lessons);
          }
        }

        final displayList = canReorder ? _optimisticLessons! : lessons;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionLabel(theme, 'Lessons', Icons.play_lesson_rounded),
                const Spacer(),
                if (_isSavingOrder)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kAccent)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${displayList.length} lessons',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kAccent)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (canReorder)
              _buildReorderableList(displayList, theme, isDark, locale)
            else
              ...displayList.map((lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LessonCard(
                      lesson: lesson,
                      locale: locale,
                      isDark: isDark,
                      theme: theme,
                      onEdit: () =>
                          context.push('/admin/add-lesson', extra: lesson),
                      onDelete: () => _confirmDelete(context, lesson),
                    ),
                  )),
            if (paginatedState.isFetchingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kAccent)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReorderableList(
      List<LessonModel> list, ThemeData theme, bool isDark, String locale) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      onReorder: (oldIndex, newIndex) => _handleReorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final lesson = list[index];
        return Padding(
          key: ValueKey(lesson.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _LessonCard(
            lesson: lesson,
            locale: locale,
            isDark: isDark,
            theme: theme,
            showDragHandle: true,
            dragIndex: index,
            onEdit: () => context.push('/admin/add-lesson', extra: lesson),
            onDelete: () => _confirmDelete(context, lesson),
          ),
        );
      },
    );
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _optimisticLessons!.removeAt(oldIndex);
      _optimisticLessons!.insert(newIndex, item);
      for (int i = 0; i < _optimisticLessons!.length; i++) {
        _optimisticLessons![i] =
            _optimisticLessons![i].copyWith(orderNumber: i + 1);
      }
      _isSavingOrder = true;
    });
    try {
      final updates = _optimisticLessons!
          .map((l) => {'id': l.id, 'order_number': l.orderNumber})
          .toList();
      await ref.read(adminRepositoryProvider).updateLessonOrders(updates);
      ref
          .read(coursesRepositoryProvider)
          .invalidateLessonsCache(_selectedSubjectId!);
      ref.invalidate(lessonsProvider(_selectedSubjectId!));
      ref.invalidate(allLessonsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving order: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        ref.invalidate(paginatedAdminLessonsProvider(_currentFilter));
      }
    } finally {
      if (mounted) setState(() => _isSavingOrder = false);
    }
  }

  void _confirmDelete(BuildContext context, LessonModel lesson) {
    final locale = Localizations.localeOf(context).languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text(
            'Are you sure you want to delete "${lesson.getTitle(locale)}"?\n\nThis action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(adminRepositoryProvider)
                    .deleteLesson(lesson.id);
                ref
                    .read(paginatedAdminLessonsProvider(_currentFilter).notifier)
                    .removeLocalLesson(lesson.id);
                ref
                    .read(coursesRepositoryProvider)
                    .invalidateLessonsCache(lesson.subjectId);
                ref.invalidate(lessonsProvider(lesson.subjectId));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Lesson deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kAccent),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withOpacity(0.7))),
      ],
    );
  }

  Widget _chip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_kAccent, _kAccentDark])
              : null,
          color: isActive
              ? null
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(11),
          border: isActive
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : _kBorderLight),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: _kAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : (isDark
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ]),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.7))),
      ),
    );
  }

  Widget _shimmerRow(bool isDark) {
    return Row(
      children: List.generate(
          3,
          (_) => Container(
                width: 72,
                height: 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(11),
                ),
              )),
    );
  }

  Widget _buildPrompt(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded,
              size: 56,
              color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('Select a level and subject',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
          const SizedBox(height: 6),
          Text('Choose filters above to view lessons',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildEmptyLessons(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 14),
          Text('No lessons found',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 6),
          Text('Add a lesson to this subject to get started',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              size: 36, color: theme.colorScheme.error),
          const SizedBox(height: 10),
          Text('Failed to load lessons',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.error)),
          const SizedBox(height: 4),
          Text(error,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onErrorContainer.withOpacity(0.7)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isFabVisible ? 1.0 : 0.0,
        child: GestureDetector(
          onTap: () => context.push('/admin/add-lesson'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_kAccent, _kAccentDark]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: _kAccent.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Add Lesson',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// _LessonCard
// ═══════════════════════════════════════════════════════════════

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final String locale;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDragHandle;
  final int? dragIndex;

  const _LessonCard({
    required this.lesson,
    required this.locale,
    required this.isDark,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    this.showDragHandle = false,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final title = lesson.getTitle(locale);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Order badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kAccent, _kAccentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${lesson.orderNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (lesson.videoUrl.isNotEmpty) ...[
                      Icon(Icons.play_circle_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text('Video',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 10),
                    ],
                    if (lesson.pdfUrl.isNotEmpty) ...[
                      Icon(Icons.picture_as_pdf_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text('PDF',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 16, color: _kAccent),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 16, color: theme.colorScheme.error),
            ),
          ),
          if (showDragHandle && dragIndex != null) ...[
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: dragIndex!,
              child: Icon(Icons.drag_handle_rounded,
                  size: 20,
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.3)),
            ),
          ],
        ],
      ),
    );
  }
}
