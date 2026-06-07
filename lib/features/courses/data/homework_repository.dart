import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/homework_submission_model.dart';

class HomeworkRepository {
  final SupabaseClient _supabase;

  HomeworkRepository(this._supabase);

  static const _bucketId = 'homework_submissions';
  static const _tableName = 'home_submissions';

  // ─── Storage ────────────────────────────────────────────────────────────────

  /// Uploads a submission file and returns the storage path.
  Future<String> uploadSubmissionFile(
    Uint8List fileBytes,
    String studentId,
    String assignmentId,
    String extension,
  ) async {
    final safeExt = extension.replaceAll('.', '').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'submissions/$studentId/${assignmentId}_$timestamp.$safeExt';

    await _supabase.storage.from(_bucketId).uploadBinary(
      path,
      fileBytes,
      fileOptions: FileOptions(
        contentType: safeExt == 'pdf' ? 'application/pdf' : 'image/$safeExt',
      ),
    );

    return path;
  }

  /// Returns a signed URL for a submission file path.
  Future<String> getSubmissionSignedUrl(String filePath) async {
    if (filePath.isEmpty) return '';
    try {
      final url = await _supabase.storage
          .from(_bucketId)
          .createSignedUrl(filePath, 60 * 60); // 1 hour
      return url;
    } catch (_) {
      return '';
    }
  }

  // ─── Student ────────────────────────────────────────────────────────────────

  /// Insert or update the student's submission for an assignment.
  Future<void> submitHomework(Map<String, dynamic> data) async {
    await _supabase.from(_tableName).upsert(
      data,
      onConflict: 'student_id,assignment_id',
      ignoreDuplicates: false,
    );
  }

  /// Returns the student's own submission, or null if not yet submitted.
  Future<HomeworkSubmissionModel?> getStudentSubmission(
    String assignmentId,
    String studentId,
  ) async {
    final res = await _supabase
        .from(_tableName)
        .select()
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (res == null) return null;
    return HomeworkSubmissionModel.fromJson(res);
  }

  // ─── Admin ──────────────────────────────────────────────────────────────────

  /// All submissions for an assignment with joined student profile info.
  Future<List<Map<String, dynamic>>> getSubmissionsForAdmin(
    String assignmentId,
  ) async {
    final data = await _supabase
        .from(_tableName)
        .select('''
          id,
          assignment_id,
          student_id,
          file_url,
          note,
          grade,
          feedback,
          status,
          submitted_at,
          graded_at,
          profiles:student_id (
            id,
            email,
            full_name
          )
        ''')
        .eq('assignment_id', assignmentId)
        .order('submitted_at', ascending: true);

    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Set grade, feedback, status → 'graded', and graded_at → now().
  Future<void> gradeSubmission(
    String submissionId, {
    required double grade,
    required String feedback,
  }) async {
    await _supabase.from(_tableName).update({
      'status': 'graded',
      'grade': grade,
      'feedback': feedback,
      'graded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', submissionId);
  }
}
