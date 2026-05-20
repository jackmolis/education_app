import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/paginated_admin_quizzes_provider.dart';
import '../widgets/admin_quiz_preview_screen.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class ManageQuizzesScreen extends ConsumerStatefulWidget {
  const ManageQuizzesScreen({super.key});

  @override
  ConsumerState<ManageQuizzesScreen> createState() => _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends ConsumerState<ManageQuizzesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedAdminQuizzesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzesState = ref.watch(paginatedAdminQuizzesProvider);
    final filteredQuizzes = ref.watch(filteredPaginatedQuizzesProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(paginatedAdminQuizzesProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/add-quiz'),
        icon: const Icon(Icons.add),
        label: const Text('Add Quiz'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by lesson or subject...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => ref.read(quizSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: quizzesState.when(
              data: (_) {
                if (filteredQuizzes == null || filteredQuizzes.quizzes.isEmpty) {
                  return const Center(child: Text('No quizzes found.'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  itemCount: filteredQuizzes.quizzes.length + (filteredQuizzes.isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredQuizzes.quizzes.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final quiz = filteredQuizzes.quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(quiz.lessonName, style: theme.textTheme.titleLarge)),
                                Chip(label: Text(quiz.subjectName), backgroundColor: theme.colorScheme.surfaceContainerHighest),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.format_list_bulleted, size: 16),
                                const SizedBox(width: 4),
                                Text('${quiz.totalQuestions} Questions'),
                                const SizedBox(width: 16),
                                const Icon(Icons.timer_outlined, size: 16),
                                const SizedBox(width: 4),
                                Text('${quiz.timeLimit}s'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AdminQuizPreviewScreen(quiz: quiz),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Preview'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit functionality is coming soon')));
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, ref, quiz.lessonId, quiz.lessonName),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String lessonId, String lessonName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: Text('Are you sure you want to permanently delete ALL questions associated with "$lessonName"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(paginatedAdminQuizzesProvider.notifier).deleteQuiz(lessonId).then((_) {
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz deleted successfully')));
                 }
              }).catchError((e) {
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
                 }
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
