import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../providers/paginated_admin_lessons_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class ManageLessonsScreen extends ConsumerStatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  ConsumerState<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends ConsumerState<ManageLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedSubjectFilter;
  bool _isFabVisible = true;
  bool _isSavingOrder = false;
  List<LessonModel>? _optimisticLessons;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
      
      // Infinite scroll listener
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final filter = AdminLessonsFilter(
          subjectId: _selectedSubjectFilter,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        );
        ref.read(paginatedAdminLessonsProvider(filter).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, LessonModel lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.getTitle(Localizations.localeOf(context).languageCode)}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(adminRepositoryProvider).deleteLesson(lesson.id);
                // Invalidate local caches
                final filter = AdminLessonsFilter(
                  subjectId: _selectedSubjectFilter,
                  searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
                );
                ref.read(paginatedAdminLessonsProvider(filter).notifier).removeLocalLesson(lesson.id);
                ref.read(coursesRepositoryProvider).invalidateLessonsCache(lesson.subjectId);
                ref.invalidate(lessonsProvider(lesson.subjectId));
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson deleted successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting lesson: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = AdminLessonsFilter(
      subjectId: _selectedSubjectFilter,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );
    final paginatedAsync = ref.watch(paginatedAdminLessonsProvider(filter));
    final subjectsAsync = ref.watch(subjectsProvider);

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Lessons'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter & Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search lessons by title...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                subjectsAsync.when(
                  data: (List<SubjectModel> subjects) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectFilter,
                      decoration: InputDecoration(
                        labelText: 'Filter by Subject',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        prefixIcon: const Icon(Icons.filter_list),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Subjects'),
                        ),
                        ...subjects.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name.isNotEmpty ? s.name : 'Untitled'),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedSubjectFilter = val);
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading subjects'),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: paginatedAsync.when(
              data: (paginatedState) {
                final filtered = paginatedState.lessons;

                if (filtered.isEmpty) {
                  return const Center(child: Text('No lessons found.'));
                }

                bool canReorder = _selectedSubjectFilter != null && _searchQuery.isEmpty;

                if (!canReorder) {
                  _optimisticLessons = null;
                } else {
                  if (_optimisticLessons == null || 
                      _optimisticLessons!.length != filtered.length || 
                      _optimisticLessons!.any((l) => !filtered.any((f) => f.id == l.id))) {
                    _optimisticLessons = List<LessonModel>.from(filtered);
                  }
                }

                final displayList = canReorder ? _optimisticLessons! : filtered;

                Widget buildCard(LessonModel lesson, int index) {
                  String subjectName = 'Unknown Subject';
                  if (subjectsAsync.hasValue) {
                    final s = subjectsAsync.value!.where((s) => s.id == lesson.subjectId).toList();
                    if (s.isNotEmpty) subjectName = s.first.getName(Localizations.localeOf(context).languageCode);
                  }

                  return Card(
                    key: ValueKey(lesson.id),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 2,
                    shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        lesson.getTitle(Localizations.localeOf(context).languageCode), 
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.library_books, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(child: Text(subjectName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.format_list_numbered, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text('Order: ${lesson.orderNumber}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                            tooltip: 'Edit Lesson',
                            onPressed: () {
                              context.push('/admin/add-lesson', extra: lesson);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            tooltip: 'Delete Lesson',
                            onPressed: () => _confirmDelete(context, lesson),
                          ),
                          if (canReorder)
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(Icons.drag_handle, color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                if (canReorder) {
                  return Stack(
                    children: [
                      ReorderableListView.builder(
                        scrollController: _scrollController,
                        padding: EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 8.0,
                          bottom: MediaQuery.paddingOf(context).bottom + 88.0,
                        ),
                        itemCount: displayList.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          
                          setState(() {
                            final item = _optimisticLessons!.removeAt(oldIndex);
                            _optimisticLessons!.insert(newIndex, item);
                            
                            for (int i = 0; i < _optimisticLessons!.length; i++) {
                              _optimisticLessons![i] = _optimisticLessons![i].copyWith(orderNumber: i + 1);
                            }
                            _isSavingOrder = true;
                          });

                          try {
                            final updates = _optimisticLessons!.map((l) => {
                              'id': l.id,
                              'order_number': l.orderNumber,
                            }).toList();
                            
                            await ref.read(adminRepositoryProvider).updateLessonOrders(updates);
                            ref.read(coursesRepositoryProvider).invalidateLessonsCache(_selectedSubjectFilter!);
                            ref.invalidate(lessonsProvider(_selectedSubjectFilter!));
                            ref.invalidate(allLessonsProvider);
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lesson order saved!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error saving order: $e'), backgroundColor: theme.colorScheme.error),
                              );
                              ref.invalidate(paginatedAdminLessonsProvider(filter));
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSavingOrder = false);
                            }
                          }
                        },
                        itemBuilder: (context, index) {
                          return buildCard(displayList[index], index);
                        },
                      ),
                      if (_isSavingOrder)
                        Positioned(
                          top: 16.0,
                          right: 16.0,
                          child: Card(
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                    bottom: MediaQuery.paddingOf(context).bottom + 88.0,
                  ),
                  itemCount: displayList.length + (paginatedState.isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayList.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return buildCard(displayList[index], index);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading lessons: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: () => context.push('/admin/add-lesson'), // Null extra creates a new one
            tooltip: 'Add New Lesson',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
