import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/admin_repository.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../widgets/math_editor.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

enum QuestionType { mcq, trueFalse, shortAnswer }

class QuestionItemState {
  QuestionType type = QuestionType.mcq;
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController shortAnswerController = TextEditingController();
  final TextEditingController timeLimitController = TextEditingController(text: '60');
  
  int correctAnswerIndex = 0;
  bool shuffleOptions = false;

  QuestionItemState() {
    optionControllers[0].text = 'True';
    optionControllers[1].text = 'False';
  }

  void dispose() {
    questionController.dispose();
    shortAnswerController.dispose();
    timeLimitController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
  }

  QuestionItemState clone() {
    final copy = QuestionItemState();
    copy.type = type;
    copy.questionController.text = questionController.text;
    copy.shortAnswerController.text = shortAnswerController.text;
    copy.timeLimitController.text = timeLimitController.text;
    copy.shuffleOptions = shuffleOptions;
    copy.correctAnswerIndex = correctAnswerIndex;
    for (int i = 0; i < optionControllers.length; i++) {
      copy.optionControllers[i].text = optionControllers[i].text;
    }
    return copy;
  }
}

class AddQuizScreen extends ConsumerStatefulWidget {
  const AddQuizScreen({super.key});

  @override
  ConsumerState<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends ConsumerState<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectId;
  String? _selectedLessonId;
  bool _isSubmitting = false;

  final List<QuestionItemState> _questions = [QuestionItemState()];

  @override
  void dispose() {
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionItemState());
    });
  }

  void _cloneQuestion(QuestionItemState q) {
    setState(() {
      _questions.add(q.clone());
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        final removed = _questions.removeAt(index);
        removed.dispose();
      });
    }
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final input = File(filePath).openRead();
        final fields = await input.transform(utf8.decoder).transform(csv.decoder).toList();

        if (fields.length <= 1) return; 

        setState(() {
          for (int i = 1; i < fields.length; i++) {
            final row = fields[i];
            if (row.isEmpty) continue;
            
            final typeStr = row.isNotEmpty ? row[0].toString().toLowerCase() : '';
            final qText = row.length > 1 ? row[1].toString() : '';
            
            final q = QuestionItemState();
            q.questionController.text = qText;
            
            if (typeStr.contains('short')) {
              q.type = QuestionType.shortAnswer;
              q.shortAnswerController.text = row.length > 6 ? row[6].toString() : '';
            } else if (typeStr.contains('true')) {
              q.type = QuestionType.trueFalse;
              q.correctAnswerIndex = (row.length > 6 ? int.tryParse(row[6].toString()) : 0) ?? 0;
            } else {
              q.type = QuestionType.mcq;
              q.optionControllers[0].text = row.length > 2 ? row[2].toString() : '';
              q.optionControllers[1].text = row.length > 3 ? row[3].toString() : '';
              q.optionControllers[2].text = row.length > 4 ? row[4].toString() : '';
              q.optionControllers[3].text = row.length > 5 ? row[5].toString() : '';
              q.correctAnswerIndex = (row.length > 6 ? int.tryParse(row[6].toString()) : 0) ?? 0;
            }
            
            final timeLimit = (row.length > 7 ? int.tryParse(row[7].toString()) : 60) ?? 60;
            q.timeLimitController.text = timeLimit.toString();
            
            final shufStr = row.length > 8 ? row[8].toString().toLowerCase() : 'false';
            q.shuffleOptions = shufStr == 'true' || shufStr == '1';
            
            _questions.add(q);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${fields.length - 1} questions!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing CSV: $e')),
        );
      }
    }
  }

  void _showPreviewDialog() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before previewing.')),
      );
      return;
    }
    if (_selectedLessonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject and lesson')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preview Final Quiz'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q${index + 1} (${q.type.name}): ${q.questionController.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (q.type == QuestionType.mcq || q.type == QuestionType.trueFalse)
                      ...List.generate(q.type == QuestionType.trueFalse ? 2 : 4, (oIndex) {
                        final isCorrect = q.correctAnswerIndex == oIndex;
                        return Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isCorrect ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(q.optionControllers[oIndex].text)),
                          ],
                        );
                      })
                    else 
                      Text('Exact match: ${q.shortAnswerController.text}', style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 8),
                    Text('Timer: ${q.timeLimitController.text}s | Shuffle: ${q.shuffleOptions}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel / Edit'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submit();
            },
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final List<Map<String, dynamic>> quizzesData = _questions.map((q) {
        Map<String, dynamic> optionsJson = {
           'type': q.type.name,
           'time_limit': int.tryParse(q.timeLimitController.text) ?? 60,
           'shuffle': q.shuffleOptions,
        };
        
        if (q.type == QuestionType.shortAnswer) {
           optionsJson['exact_match'] = q.shortAnswerController.text.trim();
        } else if (q.type == QuestionType.trueFalse) {
           optionsJson['choices'] = ['True', 'False'];
        } else {
           optionsJson['choices'] = q.optionControllers.map((c) => c.text.trim()).toList();
        }

        return {
          'lesson_id': _selectedLessonId,
          'question': q.questionController.text.trim(),
          'options': optionsJson,
          // Fallback integer for non-choice correct answers
          'correct_answer': q.type == QuestionType.shortAnswer ? 0 : q.correctAnswerIndex, 
        };
      }).toList();

      final repo = AdminRepository(Supabase.instance.client);
      await repo.addQuizzes(quizzesData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully added ${_questions.length} question(s)!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add quizzes: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppBar(title: const Text('Add Quiz Builder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Subject Dropdown ──
              subjectsAsync.when(
                data: (List<SubjectModel> subjects) => DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.book_outlined),
                  ),
                  initialValue: _selectedSubjectId,
                  items: subjects.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.getName(Localizations.localeOf(context).languageCode).isNotEmpty ? s.getName(Localizations.localeOf(context).languageCode) : 'Untitled'))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value;
                      _selectedLessonId = null;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a subject' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load subjects: $e'),
              ),
              const SizedBox(height: 16),

              // ── Lesson Dropdown ──
              if (_selectedSubjectId != null)
                ref.watch(lessonsProvider(_selectedSubjectId!)).when(
                  data: (paginatedState) {
                    final lessons = paginatedState.lessons;
                    if (lessons.isEmpty) return const Text('No lessons found for this subject.');
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Lesson',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.play_lesson_outlined),
                      ),
                      initialValue: _selectedLessonId,
                      items: lessons.map((l) => DropdownMenuItem(value: l.id, child: Text(l.getTitle(Localizations.localeOf(context).languageCode)))).toList(),
                      onChanged: (value) => setState(() => _selectedLessonId = value),
                      validator: (value) => value == null ? 'Please select a lesson' : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load lessons: $e'),
                ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   OutlinedButton.icon(
                      onPressed: _importCSV,
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Import CSV'),
                   ),
                ]
              ),
              const SizedBox(height: 16),

              // ── Questions ──
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final q = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Question ${index + 1}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  color: theme.colorScheme.primary,
                                  tooltip: 'Clone Question',
                                  onPressed: () => _cloneQuestion(q),
                                ),
                                if (_questions.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: theme.colorScheme.error,
                                    tooltip: 'Remove Question',
                                    onPressed: () => _removeQuestion(index),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<QuestionType>(
                            decoration: InputDecoration(
                                labelText: 'Question Type',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            initialValue: q.type,
                            items: const [
                                DropdownMenuItem(value: QuestionType.mcq, child: Text('Multiple Choice')),
                                DropdownMenuItem(value: QuestionType.trueFalse, child: Text('True / False')),
                                DropdownMenuItem(value: QuestionType.shortAnswer, child: Text('Short Answer')),
                            ],
                            onChanged: (val) {
                                if (val != null) {
                                    setState(() {
                                        q.type = val;
                                        if (val == QuestionType.trueFalse) {
                                            q.correctAnswerIndex = 0; // Default to True
                                        }
                                    });
                                }
                            },
                        ),
                        const SizedBox(height: 16),
                        MathEditor(
                          controller: q.questionController,
                          label: 'Question Text',
                          maxLines: 2,
                          prefixIcon: const Icon(Icons.help_outline),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Enter a question' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        if (q.type == QuestionType.mcq || q.type == QuestionType.trueFalse) ...[
                            Text('Options (Select correct answer):', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 8),
                            ...List.generate(q.type == QuestionType.trueFalse ? 2 : 4, (oIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: oIndex,
                                      groupValue: q.correctAnswerIndex,
                                      onChanged: (val) {
                                        if (val != null) setState(() => q.correctAnswerIndex = val);
                                      },
                                    ),
                                    Expanded(
                                      child: q.type == QuestionType.trueFalse
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                                            child: Text(oIndex == 0 ? 'True' : 'False', style: const TextStyle(fontSize: 16)),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              MathEditor(
                                                controller: q.optionControllers[oIndex],
                                                label: 'Option ${oIndex + 1}',
                                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                              ),
                                            ],
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ] else ...[
                            MathEditor(
                                controller: q.shortAnswerController,
                                label: 'Exact Short Answer Phrase',
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(),
                        Row(
                           children: [
                               Expanded(
                                   child: TextFormField(
                                       controller: q.timeLimitController,
                                       keyboardType: TextInputType.number,
                                       decoration: InputDecoration(
                                           labelText: 'Time Limit (Seconds)',
                                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                           prefixIcon: const Icon(Icons.timer_outlined),
                                       ),
                                       validator: (value) => value == null || int.tryParse(value) == null ? 'Invalid integer' : null,
                                   ),
                               ),
                               const SizedBox(width: 16),
                               Column(
                                   children: [
                                       const Text('Shuffle Options', style: TextStyle(fontSize: 12)),
                                       Switch(
                                           value: q.shuffleOptions, 
                                           onChanged: q.type == QuestionType.trueFalse ? null : (val) => setState(() => q.shuffleOptions = val),
                                       ),
                                   ],
                               )
                           ]
                        )
                      ],
                    ),
                  ),
                );
              }),
              
              // ── Actions ──
              OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Blank Question'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _showPreviewDialog,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.preview),
                label: Text(_isSubmitting ? 'Processing...' : 'Preview & Save'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
