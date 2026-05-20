class UserProgressModel {
  final String id;
  final String userId;
  final String lessonId;
  final String subjectId;
  final DateTime completedAt;

  UserProgressModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.subjectId,
    required this.completedAt,
  });

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      subjectId: json['subject_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'subject_id': subjectId,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}
