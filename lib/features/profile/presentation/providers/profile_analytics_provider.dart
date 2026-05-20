import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../../courses/data/progress_repository.dart';
import '../../data/profile_providers.dart';

class ProfileAnalytics {
  final double averageScore;
  final String insightMessage;
  final List<double> scoreHistory;
  
  ProfileAnalytics({
    required this.averageScore,
    required this.insightMessage,
    required this.scoreHistory,
  });
}

final profileAnalyticsProvider = Provider.autoDispose<ProfileAnalytics>((ref) {
  final quizResultsAsync = ref.watch(userQuizResultsProvider);
  
  return quizResultsAsync.maybeWhen(
    data: (results) {
      if (results.isEmpty) {
        return ProfileAnalytics(
          averageScore: 0, 
          insightMessage: 'No initial data. Take a quiz!', 
          scoreHistory: []
        );
      }
      
      final chronologicalResults = results.reversed.toList();
      final scoreHistory = chronologicalResults.map((r) => (r.score / r.total) * 100).toList();
      
      final sum = scoreHistory.fold<double>(0, (prev, element) => prev + element);
      final avg = sum / scoreHistory.length;
      
      String insight = 'Needs improvement';
      if (avg >= 80) insight = 'Excellent performance';
      else if (avg >= 50) insight = 'Good, keep improving';
      
      return ProfileAnalytics(
        averageScore: avg,
        insightMessage: insight,
        scoreHistory: scoreHistory,
      );
    },
    orElse: () => ProfileAnalytics(averageScore: 0, insightMessage: 'Loading analysis...', scoreHistory: []),
  );
});

final totalSystemLessonsProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.getTotalLessonsCount();
});

final globalProgressProvider = FutureProvider.autoDispose<double>((ref) async {
  final completedAsync = await ref.watch(totalCompletedLessonsProvider.future);
  final totalAsync = await ref.watch(totalSystemLessonsProvider.future);
  
  if (totalAsync == 0) return 0.0;
  return (completedAsync) / totalAsync;
});
