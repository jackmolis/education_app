class AdminAnalyticsModel {
  final int totalSubjects;
  final int totalLessons;
  final int totalQuizzes;
  final int totalVideoProgress;
  final List<int> quizActivity;

  AdminAnalyticsModel({
    required this.totalSubjects,
    required this.totalLessons,
    required this.totalQuizzes,
    required this.totalVideoProgress,
    required this.quizActivity,
  });
}
