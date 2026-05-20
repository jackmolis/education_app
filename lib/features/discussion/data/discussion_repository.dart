import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentModel {
  final String id;
  final String userId;
  final String lessonId;
  final String content;
  final DateTime createdAt;
  final String? userEmail;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.content,
    required this.createdAt,
    this.userEmail,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return CommentModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: parsedDate,
      userEmail: json['user_email']?.toString(),
    );
  }
}

class DiscussionRepository {
  final SupabaseClient _supabase;

  DiscussionRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

      /// Add a new comment.
  Future<void> addComment({
    required String userId,
    required String lessonId,
    required String content,
    String? userEmail,
  }) async {
    debugPrint('[Discussion] addComment for lessonId: $lessonId');
    await _supabase.from('comments').insert({
      'user_id': userId,
      'lesson_id': lessonId,
      'content': content,
      'user_email': userEmail,
    });
    debugPrint('[Discussion] Comment added successfully');
  }

  /// Real-time stream of comments for a lesson.
  Stream<List<CommentModel>> watchComments(String lessonId) {
    debugPrint('[Discussion] watchComments stream created for lessonId: $lessonId');
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('lesson_id', lessonId)
        .order('created_at', ascending: true)
        .map((rows) {
      debugPrint('[Discussion] Stream emitted ${rows.length} comments for $lessonId');
      if (rows.isNotEmpty) {
        debugPrint('[Discussion] First row keys: ${rows.first.keys.toList()}');
      }
      return rows.map((e) => CommentModel.fromJson(e)).toList();
    });
  }
}
