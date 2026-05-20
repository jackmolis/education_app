import 'package:flutter/material.dart';
import '../../domain/admin_quiz_summary_model.dart';
import '../../../../core/widgets/smart_math_view.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class AdminQuizPreviewScreen extends StatelessWidget {
  final AdminQuizSummaryModel quiz;

  const AdminQuizPreviewScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: AppScaffold(
        appBar: AppBar(
          title: Text('${quiz.lessonName} - Quiz Preview'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: quiz.questions.length,
          itemBuilder: (context, index) {
            final q = quiz.questions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(label: Text(q.type.toUpperCase(), style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SmartMathView(text: q.questionText, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (q.type == 'shortAnswer')
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: SmartMathView(text: q.correctAnswer, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      )
                    else
                      ...List.generate(q.options.length, (optIndex) {
                        final optionText = q.options[optIndex];
                        final isCorrect = optionText == q.correctAnswer;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isCorrect ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: SmartMathView(text: optionText)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
