import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../data/admin_analytics_service.dart';
import '../../domain/admin_analytics_model.dart';

final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AdminAnalyticsService(supabaseClient);
});

final adminStatsProvider = FutureProvider.autoDispose<AdminAnalyticsModel>((ref) async {
  final service = ref.watch(adminAnalyticsServiceProvider);
  
  // Use Future.wait to run the counts natively in parallel, dodging Supabase RPC nested aggregation limits
  final results = await Future.wait([
    service.getSubjectsCount(),
    service.getLessonsCount(),
    service.getQuizzesCount(),
    service.getVideoProgressCount(),
    service.getQuizActivity(),
  ]);

  return AdminAnalyticsModel(
    totalSubjects: results[0] as int,
    totalLessons: results[1] as int,
    totalQuizzes: results[2] as int,
    totalVideoProgress: results[3] as int,
    quizActivity: results[4] as List<int>,
  );
});
