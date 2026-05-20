import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/supabase_auth_repository.dart';
import '../../courses/domain/models/lesson_model.dart';
import 'admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AdminRepository(supabaseClient);
});

final allLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final rawData = await repo.getAllLessons();
  return rawData.map((json) => LessonModel.fromJson(json)).toList();
});
