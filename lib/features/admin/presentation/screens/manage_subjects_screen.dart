import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/domain/models/subject_model.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class ManageSubjectsScreen extends ConsumerWidget {
  const ManageSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/add-subject'),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: subjectsAsync.when(
        data: (List<SubjectModel> subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects found.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88), // bottom padding for FAB
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      image: (subject.imageUrl ?? '').isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(subject.imageUrl ?? ''),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (subject.imageUrl ?? '').isEmpty
                        ? Icon(Icons.menu_book, color: colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  title: Text(
                    subject.getName(Localizations.localeOf(context).languageCode),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    subject.description ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: colorScheme.primary,
                        tooltip: 'Edit Subject',
                        onPressed: () => _showEditDialog(context, ref, subject),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: colorScheme.error,
                        tooltip: 'Delete Subject',
                        onPressed: () => _showDeleteDialog(context, ref, subject),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load subjects:\n$error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(subjectsProvider),
                  child: const Text('Try Again'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, SubjectModel subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.getName(Localizations.localeOf(context).languageCode)}"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // close dialog
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              try {
                await ref.read(adminRepositoryProvider).deleteSubject(subject.id);
                ref.read(coursesRepositoryProvider).clearSubjectsCache();
                ref.invalidate(subjectsProvider);
                
                if (!ctx.mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Subject deleted successfully.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              } catch (e) {
                // Ignore the error if it contains constraints issues or general PG error
                // Realistically, the error means they couldn't delete. 
                String errorMsg = e.toString();
                if (errorMsg.contains('foreign key constraint') || errorMsg.contains('23503')) {
                  errorMsg = 'Cannot delete subject because it contains lessons or quizzes.';
                }

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed: $errorMsg'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, SubjectModel subject) {
    final nameController = TextEditingController(text: subject.getName(Localizations.localeOf(context).languageCode));
    final descController = TextEditingController(text: subject.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Subject'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Subject Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Please enter a description' : null,
                    ),
                  ],
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
                          
                          setState(() => isSaving = true);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          try {
                            await ref.read(adminRepositoryProvider).updateSubject(
                              subject.id,
                              {
                                'name': nameController.text.trim(),
                                'description': descController.text.trim(),
                              },
                            );
                            ref.read(coursesRepositoryProvider).clearSubjectsCache();
                            ref.invalidate(subjectsProvider);
                            
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: const Text('Subject updated successfully.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                                backgroundColor: Colors.green.shade600,
                              ),
                            );
                          } catch (e) {
                            setState(() => isSaving = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Error updating subject: $e'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
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
