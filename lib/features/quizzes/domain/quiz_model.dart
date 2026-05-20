class QuizModel {
  final String id;
  final String lessonId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String type;
  final int timeLimit;
  final bool shuffle;

  QuizModel({
    required this.id,
    required this.lessonId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.type = 'mcq',
    this.timeLimit = 60,
    this.shuffle = false,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    String parsedType = 'mcq';
    int parsedTimeLimit = 60;
    bool parsedShuffle = false;

    if (rawOptions is Map<String, dynamic>) {
      parsedType = rawOptions['type']?.toString() ?? 'mcq';
      parsedTimeLimit = (rawOptions['time_limit'] as num?)?.toInt() ?? 60;
      parsedShuffle = rawOptions['shuffle'] == true;

      if (parsedType == 'shortAnswer') {
        final exactMatch = rawOptions['exact_match']?.toString() ?? '';
        parsedOptions = [exactMatch];
      } else {
        final choices = rawOptions['choices'];
        if (choices is List) {
          parsedOptions = choices.map((e) => e.toString()).toList();
        }
      }
    } else if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    String parsedCorrectAnswer = '';
    final rawCorrectAnswer = json['correct_answer'];

    if (rawCorrectAnswer != null) {
      if (rawCorrectAnswer is int) {
        if (rawCorrectAnswer >= 0 && rawCorrectAnswer < parsedOptions.length) {
          parsedCorrectAnswer = parsedOptions[rawCorrectAnswer];
        } else {
          parsedCorrectAnswer = rawCorrectAnswer.toString();
        }
      } else {
        final strVal = rawCorrectAnswer.toString();
        final intVal = int.tryParse(strVal);
        if (intVal != null && intVal >= 0 && intVal < parsedOptions.length) {
          parsedCorrectAnswer = parsedOptions[intVal];
        } else {
          parsedCorrectAnswer = strVal; // Pre-resolved string or fallback
        }
      }
    }

    if (parsedType == 'shortAnswer' && parsedOptions.isNotEmpty) {
      parsedCorrectAnswer = parsedOptions.first;
    }

    return QuizModel(
      id: json['id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      questionText: json['question']?.toString() ?? '',
      options: parsedOptions,
      correctAnswer: parsedCorrectAnswer,
      type: parsedType,
      timeLimit: parsedTimeLimit,
      shuffle: parsedShuffle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'question': questionText,
      'options': {
        'type': type,
        'time_limit': timeLimit,
        'shuffle': shuffle,
        if (type == 'shortAnswer') 'exact_match': options.isNotEmpty ? options.first : '' else 'choices': options,
      },
      'correct_answer': correctAnswer,
    };
  }
}
