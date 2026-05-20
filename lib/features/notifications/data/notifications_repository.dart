import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/notification_model.dart';

class NotificationsRepository {
  final SupabaseClient _supabase;

  NotificationsRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    final data = await _supabase
        .from('notifications')
        .select(
          'id, user_id, title, body, is_read, created_at, subject_id, lesson_id, lessons(title), subjects(name)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);

      final lesson = json['lessons'] as Map<String, dynamic>?;
      final subject = json['subjects'] as Map<String, dynamic>?;
      final lessonTitle = lesson?['title']?.toString() ?? '';
      final subjectName = subject?['name']?.toString() ?? '';

      if (lessonTitle.isNotEmpty && subjectName.isNotEmpty) {
        json['body'] = '$lessonTitle added to $subjectName';
      }

      return NotificationModel.fromJson(json);
    }).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<int> getUnreadCount(String userId) async {
    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }
}
