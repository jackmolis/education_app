import 'package:flutter/material.dart';
import '../../domain/models/quiz_result_model.dart';

class QuizResultListTile extends StatelessWidget {
  final QuizResultModel result;

  const QuizResultListTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final percentage = (result.score / result.total) * 100;
    final isPassing = percentage >= 50;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPassing
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2),
        child: Icon(
          isPassing ? Icons.check : Icons.close,
          color: isPassing ? Colors.green : Colors.red,
        ),
      ),
      title: Text('${result.lessonTitle} Quiz'),
      trailing: Text(
        '${result.score}/${result.total}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isPassing ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
