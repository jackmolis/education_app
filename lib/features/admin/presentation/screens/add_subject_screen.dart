import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class AddSubjectScreen extends ConsumerStatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  ConsumerState<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends ConsumerState<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameFrController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _pickedImageName;
  Uint8List? _pickedImageBytes;
  bool _isSubmitting = false;
  String? _selectedLevelId;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameFrController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a level before saving.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(adminRepositoryProvider);

      String imageUrl = '';
      if (_pickedImageBytes != null) {
        final ext = _pickedImageName?.split('.').last ?? 'jpg';
        imageUrl = await repo.uploadSubjectImageBytes(
          _pickedImageBytes!,
          ext,
        );
      }

      final subjectData = {
        'name': _nameArController.text.trim(),
        'name_en': _nameEnController.text.trim(),
        'name_fr': _nameFrController.text.trim(),
        'name_ar': _nameArController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'level_id': _selectedLevelId!,
      };

      debugPrint('Inserting subject with level_id: $_selectedLevelId');
      await repo.addSubjectWithDetails(subjectData);

      // Clear repository cache so getSubjects() does not return stale list
      ref.read(coursesRepositoryProvider).clearSubjectsCache();
      ref.invalidate(subjectsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Subject added successfully!')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.green.shade600,
            margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          ),
        );

        // Clear input after success
        _nameEnController.clear();
        _nameFrController.clear();
        _nameArController.clear();
        _descriptionController.clear();
        setState(() {
          _pickedImageName = null;
          _pickedImageBytes = null;
          _selectedLevelId = null;
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to add subject: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Subject'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Subject Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the information below to create a new subject.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Level Dropdown (fetched from Supabase) ──
                  Builder(builder: (context) {
                    final levelsAsync = ref.watch(levelsProvider);
                    return levelsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, st) {
                        debugPrint('Error loading levels: $e');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Failed to load levels: $e', style: const TextStyle(color: Colors.red)),
                        );
                      },
                      data: (levels) {
                        debugPrint('Levels loaded for Add Subject: ${levels.length}');
                        return DropdownButtonFormField<String>(
                          key: const ValueKey('add_subject_level_dropdown'),
                          value: _selectedLevelId,
                          decoration: InputDecoration(
                            labelText: 'Level',
                            hintText: 'Select a level',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            prefixIcon: Icon(Icons.school_outlined, color: colorScheme.primary),
                          ),
                          items: levels.map<DropdownMenuItem<String>>((level) {
                            return DropdownMenuItem<String>(
                              value: level.id,
                              child: Text(level.name.isNotEmpty ? level.name : 'Unnamed Level'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            debugPrint('Level selected: $value');
                            setState(() => _selectedLevelId = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a level';
                            }
                            return null;
                          },
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameEnController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name (English)',
                      hintText: 'e.g. Mathematics',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      prefixIcon: Icon(Icons.language, color: colorScheme.primary),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameFrController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name (French)',
                      hintText: 'e.g. Mathématiques',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      prefixIcon: Icon(Icons.language, color: colorScheme.primary),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameArController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name (Arabic)',
                      hintText: 'e.g. رياضيات',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      prefixIcon: Icon(Icons.language, color: colorScheme.primary),
                    ),
                    textDirection: TextDirection.rtl,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Learn core math concepts',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      prefixIcon: Icon(Icons.description_outlined, color: colorScheme.primary),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Cover Image',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _pickedImageBytes != null
                                    ? (_pickedImageName ?? 'Image selected')
                                    : 'No image selected',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _pickedImageBytes != null 
                                    ? colorScheme.onSurface 
                                    : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.tonalIcon(
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );
                                      if (result == null || result.files.isEmpty) return;
                                      final file = result.files.single;
                                      if (file.bytes == null) return;
                                      setState(() {
                                        _pickedImageName = file.name;
                                        _pickedImageBytes = file.bytes;
                                      });
                                    },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Browse'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(
                      _isSubmitting ? 'Saving Subject...' : 'Save Subject',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
