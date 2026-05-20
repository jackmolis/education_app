import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_profile_repository.dart';
import '../domain/profile_repository.dart';
import '../domain/models/user_profile_model.dart';
import '../domain/models/quiz_result_model.dart';
import '../../authentication/data/supabase_auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

final userProfileProvider = FutureProvider.autoDispose<UserProfileModel?>((
  ref,
) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return null;
  }

  return ref.watch(profileRepositoryProvider).getUserProfile(user.id);
});

final userQuizResultsProvider =
    FutureProvider.autoDispose<List<QuizResultModel>>((ref) async {
      final authState = ref.watch(authStateChangesProvider);
      final user = authState.value;

      if (user == null) {
        return [];
      }

      return ref.watch(profileRepositoryProvider).getUserQuizResults(user.id);
    });
