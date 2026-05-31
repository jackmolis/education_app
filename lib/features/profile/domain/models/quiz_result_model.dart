class QuizResultModel {
  final String id;
  final String userId;
  final String lessonId;
  final String lessonTitle;
  final int score;
  final int total;
  final DateTime createdAt;

  QuizResultModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.lessonTitle,
    required this.score,
    required this.total,
    required this.createdAt,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      // Handle the join from lessons table if available, else fallback securely
      lessonTitle: _firstNonEmpty([
            json['lessons']?['title_en'],
            json['lessons']?['title_fr'],
            json['lessons']?['title_ar'],
          ]) ??
          'Lesson ${json['lesson_id']}',
      score: (json['score'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'score': score,
      'total': total,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns the first non-empty localized value, or null if all are empty.
  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      final s = v?.toString() ?? '';
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}
