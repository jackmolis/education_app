import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/video_progress_model.dart';

class VideoProgressRepository {
  final SupabaseClient _supabase;

  VideoProgressRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Upsert (insert or update) the video position for a user+lesson pair.
  Future<void> saveProgress({
    required String userId,
    required String lessonId,
    required String subjectId,
    required double positionSeconds,
    required double durationSeconds,
  }) async {
    await _supabase.from('video_progress').upsert(
      {
        'user_id': userId,
        'lesson_id': lessonId,
        'subject_id': subjectId,
        'position_seconds': positionSeconds,
        'duration_seconds': durationSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,lesson_id',
    );
  }

  /// Returns the saved position for a specific lesson, or null if never watched.
  Future<VideoProgressModel?> getProgress({
    required String userId,
    required String lessonId,
  }) async {
    final data = await _supabase
        .from('video_progress')
        .select()
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (data == null) return null;
    return VideoProgressModel.fromJson(data);
  }

  /// Returns the most recently watched lesson entry for the user.
  Future<VideoProgressModel?> getLastWatched(String userId) async {
    final data = await _supabase
        .from('video_progress')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return VideoProgressModel.fromJson(data);
  }

  /// Returns weekly activity counts (Mon→Sun) based on video_progress updated_at.
  Future<List<int>> getWeeklyProgress(String userId) async {
    final now = DateTime.now();
    // Calculate the start of this week (Monday 00:00:00)
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final data = await _supabase
        .from('video_progress')
        .select('updated_at')
        .eq('user_id', userId)
        .gte('updated_at', monday.toIso8601String())
        .order('updated_at', ascending: true);

    // Count entries per weekday (1=Mon...7=Sun → index 0...6)
    final counts = List<int>.filled(7, 0);
    for (final row in data) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      final dayIndex = updatedAt.weekday - 1; // 0=Mon...6=Sun
      counts[dayIndex]++;
    }
    return counts;
  }

  /// Calculates the user's current learning streak (consecutive days).
  Future<int> getUserStreak(String userId) async {
    final data = await _supabase
        .from('video_progress')
        .select('updated_at')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    if (data.isEmpty) return 0;

    // Collect unique dates (year-month-day, local time)
    final uniqueDays = <DateTime>{};
    for (final row in data) {
      final dt = DateTime.parse(row['updated_at'] as String).toLocal();
      uniqueDays.add(DateTime(dt.year, dt.month, dt.day));
    }

    // Sort descending
    final sortedDays = uniqueDays.toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // Streak must start from today or yesterday
    if (sortedDays.first != todayDate && sortedDays.first != yesterday) {
      return 0;
    }

    int streak = 0;
    DateTime expected = sortedDays.first;

    for (final day in sortedDays) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (day.isBefore(expected)) {
        // Gap found — streak broken
        break;
      }
    }

    return streak;
  }
}
