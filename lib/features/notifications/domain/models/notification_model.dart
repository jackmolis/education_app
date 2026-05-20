class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String? subjectId;
  final String? lessonId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.subjectId,
    this.lessonId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      subjectId: json['subject_id'] as String?,
      lessonId: json['lesson_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
