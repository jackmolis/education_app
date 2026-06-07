import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/homework_provider.dart';
import '../../../courses/domain/models/home_assignment_model.dart';

typedef AdminAssignmentsFilter = ({String? subjectId});

/// Assignments for the admin management screen, filtered by subject.
final adminAssignmentsProvider =
    FutureProvider.family<List<HomeAssignmentModel>, AdminAssignmentsFilter>(
        (ref, filter) async {
  final repo = ref.watch(adminRepositoryProvider);
  final raw =
      await repo.getHomeAssignmentsForAdmin(subjectId: filter.subjectId);
  return raw.map(HomeAssignmentModel.fromJson).toList();
});

/// All submissions for an assignment (admin view).
final adminSubmissionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  assignmentId,
) async {
  final repo = ref.watch(homeworkRepositoryProvider);
  return repo.getSubmissionsForAdmin(assignmentId);
});
