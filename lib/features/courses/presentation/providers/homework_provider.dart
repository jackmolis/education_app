import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/homework_repository.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../domain/models/homework_submission_model.dart';

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return HomeworkRepository(supabaseClient);
});

/// Watches the student's current submission for a specific assignment.
final studentSubmissionProvider =
    FutureProvider.autoDispose.family<HomeworkSubmissionModel?, String>((
  ref,
  assignmentId,
) async {
  final repo = ref.watch(homeworkRepositoryProvider);
  final userId = ref.watch(authStateChangesProvider).value?.id;
  if (userId == null || userId.isEmpty) return null;
  return repo.getStudentSubmission(assignmentId, userId);
});

enum SubmitHomeworkState { idle, uploading, success, error }

class SubmitHomeworkController
    extends AutoDisposeAsyncNotifier<SubmitHomeworkState> {
  @override
  Future<SubmitHomeworkState> build() async => SubmitHomeworkState.idle;

  Future<void> submit({
    required Uint8List fileBytes,
    required String extension,
    required String assignmentId,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(homeworkRepositoryProvider);
      final userId = ref.read(authStateChangesProvider).value?.id ?? '';
      if (userId.isEmpty) throw Exception('User not authenticated');

      // 1. Upload file → get back the storage path
      final filePath = await repo.uploadSubmissionFile(
        fileBytes,
        userId,
        assignmentId,
        extension,
      );

      // 2. Upsert the submission row using plain Map (matches home_submissions columns)
      final note = notes?.trim();
      await repo.submitHomework({
        'assignment_id': assignmentId,
        'student_id': userId,
        'file_url': filePath,
        if (note != null && note.isNotEmpty) 'note': note,
        'status': 'pending',
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
      });

      state = const AsyncData(SubmitHomeworkState.success);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final submitHomeworkControllerProvider = AutoDisposeAsyncNotifierProvider<
    SubmitHomeworkController, SubmitHomeworkState>(
  SubmitHomeworkController.new,
);
