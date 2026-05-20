class VideoProgressModel {
  final String id;
  final String userId;
  final String lessonId;
  final String subjectId;
  final double positionSeconds;
  final double durationSeconds;
  final DateTime updatedAt;

  VideoProgressModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.subjectId,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  double get progressFraction {
    if (durationSeconds <= 0) return 0.0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  factory VideoProgressModel.fromJson(Map<String, dynamic> json) {
    return VideoProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      subjectId: json['subject_id'] as String,
      positionSeconds: (json['position_seconds'] as num).toDouble(),
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
