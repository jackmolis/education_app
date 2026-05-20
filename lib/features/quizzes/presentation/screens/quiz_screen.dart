import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_provider.dart';
import '../../../../core/widgets/smart_math_view.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class QuizScreen extends ConsumerWidget {
  final String subjectId;
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizFutureProvider(lessonId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: quizAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('No quiz available for this lesson.'),
            );
          }

          final quizState = ref.watch(quizProvider(questions));
          final quizNotifier = ref.read(quizProvider(questions).notifier);

          if (quizState.isCompleted) {
            Future.microtask(() {
              if (context.mounted) {
                context.pushReplacement(
                  '/subjects/${Uri.encodeComponent(subjectId)}/lessons/$lessonId/quiz/result',
                );
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final currentQuestion = questions[quizState.currentIndex];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${quizState.currentIndex + 1} of ${questions.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: SmartMathView(
                    text: currentQuestion.questionText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (currentQuestion.type == 'shortAnswer')
                  _ShortAnswerInput(
                    onSubmit: (text) {
                      quizNotifier.answerQuestion(
                        text,
                        lessonId,
                        ref.read(quizRepositoryProvider),
                      );
                    },
                  )
                else
                  ...currentQuestion.options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          quizNotifier.answerQuestion(
                            option,
                            lessonId,
                            ref.read(quizRepositoryProvider),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SmartMathView(
                            text: option,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quiz...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load quiz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(quizFutureProvider(lessonId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortAnswerInput extends StatefulWidget {
  final Function(String) onSubmit;

  const _ShortAnswerInput({required this.onSubmit});

  @override
  State<_ShortAnswerInput> createState() => _ShortAnswerInputState();
}

class _ShortAnswerInputState extends State<_ShortAnswerInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Type your answer here',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: widget.onSubmit,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSubmit(_controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Submit Answer', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
