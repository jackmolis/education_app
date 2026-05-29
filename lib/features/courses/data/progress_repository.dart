import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/data/supabase_auth_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ProgressRepository(supabaseClient);
});

// Provides a list of ONLY the lesson IDs that the user has completed.
// NOT autoDispose — persists across navigation to avoid refetching on every screen visit.
final completedLessonIdsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  
  if (user == null) return [];
  return repo.getCompletedLessonIds(user.id);
});

// Provides the percentage of completed lessons for a specific subject.
// Uses keepAlive via ref.keepAlive() pattern — cached in Hive so repeated
// visits don't re-query Supabase.
final subjectProgressProvider = FutureProvider.autoDispose.family<double, String>((ref, subjectId) async {
  // Keep alive for 60 seconds after last listener detaches to avoid
  // refetching when scrolling back to the same card.
  final link = ref.keepAlive();
  Future.delayed(const Duration(seconds: 60), () => link.close());

  final repo = ref.watch(progressRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;
  
  if (user == null) return 0.0;
  return repo.getSubjectProgressPercentage(user.id, subjectId);
});

// Provides the total count of completed lessons across all subjects.
// Derives from completedLessonIdsProvider to avoid a duplicate Supabase query.
final totalCompletedLessonsProvider = FutureProvider<int>((ref) async {
  final completed = await ref.watch(completedLessonIdsProvider.future);
  return completed.length;
});


class ProgressRepository {
  final SupabaseClient _supabaseClient;

  ProgressRepository(this._supabaseClient);

  Future<bool> _isOffline() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty) return true;
    return results.every((element) => element == ConnectivityResult.none);
  }

  Future<void> syncOfflineProgress() async {
    final box = Hive.box('offline_progress');
    if (box.isEmpty) return;

    debugPrint('Syncing ${box.length} offline progress actions...');
    final keys = box.keys.toList();
    for (var key in keys) {
      final dataStr = box.get(key);
      if (dataStr != null) {
        final data = jsonDecode(dataStr);
        try {
          await _supabaseClient.from('user_progress').insert({
            'user_id': data['user_id'],
            'lesson_id': data['lesson_id'],
            'subject_id': data['subject_id'],
          });
          await box.delete(key);
        } catch (e) {
          debugPrint('Failed to sync offline progress action: $e');
          if (e.toString().contains('duplicate key') || e.toString().contains('already exists')) {
             await box.delete(key);
          }
        }
      }
    }
  }

  Future<void> markLessonAsCompleted(String userId, String lessonId, String subjectId) async {
    final offline = await _isOffline();
    if (offline) {
      debugPrint('Offline: queuing progress for lesson $lessonId...');
      final box = Hive.box('offline_progress');
      final action = {
        'user_id': userId,
        'lesson_id': lessonId,
        'subject_id': subjectId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await box.add(jsonEncode(action));
    } else {
      try {
        await _supabaseClient.from('user_progress').insert({
          'user_id': userId,
          'lesson_id': lessonId,
          'subject_id': subjectId,
        });
      } catch (e) {
        throw Exception('Failed to mark lesson as completed: $e');
      }
    }
  }

  Future<int> getTotalLessonsCount() async {
    final offline = await _isOffline();
    final cacheBox = Hive.box('progress_cache');
    final cacheKey = 'total_system_lessons_count';

    if (offline) {
      final cachedVal = cacheBox.get(cacheKey);
      if (cachedVal != null) return cachedVal as int;
      return 0;
    }

    try {
      final int count = await _supabaseClient
          .from('lessons')
          .count(CountOption.exact);
          
      await cacheBox.put(cacheKey, count);
      return count;
    } catch (e) {
      final cachedVal = cacheBox.get(cacheKey);
      if (cachedVal != null) return cachedVal as int;
      return 0;
    }
  }

  Future<List<String>> getCompletedLessonIds(String userId) async {
    final offline = await _isOffline();
    final cacheBox = Hive.box('progress_cache');
    final cacheKey = 'completed_lessons_$userId';

    if (offline) {
      final cachedList = cacheBox.get(cacheKey);
      List<String> result = [];
      if (cachedList != null) {
        result = List<String>.from(jsonDecode(cachedList));
      }
      
      final offlineBox = Hive.box('offline_progress');
      for (var key in offlineBox.keys) {
         final dataStr = offlineBox.get(key);
         if (dataStr != null) {
             final data = jsonDecode(dataStr);
             if (data['user_id'] == userId) {
                result.add(data['lesson_id']);
             }
         }
      }
      return result.toSet().toList();
    }

    try {
      final response = await _supabaseClient
          .from('user_progress')
          .select('lesson_id')
          .eq('user_id', userId);

      final lessons = (response as List).map((row) => row['lesson_id'] as String).toList();
      await cacheBox.put(cacheKey, jsonEncode(lessons));
      return lessons;
    } catch (e) {
      final cachedList = cacheBox.get(cacheKey);
      if (cachedList != null) {
         return List<String>.from(jsonDecode(cachedList));
      }
      throw Exception('Failed to fetch completed lessons: $e');
    }
  }

  Future<double> getSubjectProgressPercentage(String userId, String subjectId) async {
    final offline = await _isOffline();
    final cacheBox = Hive.box('progress_cache');
    final cacheKey = 'progress_pct_${userId}_$subjectId';

    if (offline) {
       final cachedVal = cacheBox.get(cacheKey);
       if (cachedVal != null) return cachedVal as double;
       return 0.0;
    }

    try {
      final int totalLessonsCount = await _supabaseClient
          .from('lessons')
          .count(CountOption.exact)
          .eq('subject_id', subjectId);
          
      if (totalLessonsCount == 0) return 0.0;

      final int completedCount = await _supabaseClient
          .from('user_progress')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .eq('subject_id', subjectId);

      final pct = completedCount / totalLessonsCount;
      await cacheBox.put(cacheKey, pct);
      return pct;
    } catch (e) {
      final cachedVal = cacheBox.get(cacheKey);
      if (cachedVal != null) return cachedVal as double;
      throw Exception('Failed to calculate progress: $e');
    }
  }
}
