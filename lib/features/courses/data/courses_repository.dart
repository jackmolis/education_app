import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/subject_model.dart';
import '../domain/models/lesson_model.dart';

class CoursesRepository {
  final SupabaseClient _supabase;

  CoursesRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // In-memory cache
  List<SubjectModel>? _cachedSubjects;
  final Map<String, List<LessonModel>> _cachedLessons = {};

  /// Clears cached subjects so the next [getSubjects] call hits Supabase.
  void clearSubjectsCache() {
    _cachedSubjects = null;
  }

  Future<bool> _isOffline() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty) return true;
    return results.every((element) => element == ConnectivityResult.none);
  }

  Future<List<SubjectModel>> getSubjects({bool forceRefresh = false}) async {
    final offline = await _isOffline();
    final box = Hive.box('subjects');

    if (offline) {
      debugPrint('Fetching subjects from Hive (Offline Mode)...');
      final cachedData = box.get('all_subjects');
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        _cachedSubjects = decoded.map<SubjectModel>((json) => SubjectModel.fromJson(json as Map<String, dynamic>)).toList();
        return _cachedSubjects!;
      }
      throw Exception('You are offline and no subjects are cached.');
    }

    if (!forceRefresh && _cachedSubjects != null) {
      debugPrint('Returning cached subjects: ${_cachedSubjects!.length}');
      return _cachedSubjects!;
    }
    
    try {
      debugPrint('Fetching subjects from Supabase...');
      final data = await _supabase.from('subjects').select('id, name, description, image_url, created_at');
      debugPrint('Subjects fetched successfully: ${data.length} items');
      
      _cachedSubjects = (data as List)
          .map<SubjectModel>((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Save to Hive for offline mode
      final encoded = jsonEncode(_cachedSubjects!.map((s) => s.toJson()).toList());
      await box.put('all_subjects', encoded);
      
      return _cachedSubjects!;
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      final cachedData = box.get('all_subjects');
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        _cachedSubjects = decoded.map<SubjectModel>((json) => SubjectModel.fromJson(json as Map<String, dynamic>)).toList();
        return _cachedSubjects!;
      }
      throw Exception('Failed to fetch subjects: $e');
    }
  }

  /// Clears cached lessons for [subjectId] so the next getLessons refetches from Supabase.
  void invalidateLessonsCache(String subjectId) {
    _cachedLessons.remove(subjectId);
  }

  Future<List<LessonModel>> getLessons(
    String subjectId, {
    int limit = 10,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final offline = await _isOffline();
    final box = Hive.box('lessons');
    final cacheKey = 'lessons_$subjectId';

    if (offline) {
      debugPrint('Fetching lessons from Hive (Offline Mode) for $subjectId...');
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final allLessons = decoded.map((json) => LessonModel.fromJson(json as Map<String, dynamic>)).toList();
        _cachedLessons[subjectId] = allLessons;
        final end = (offset + limit > allLessons.length) ? allLessons.length : offset + limit;
        if (offset >= allLessons.length) return [];
        return allLessons.sublist(offset, end);
      }
      if (offset == 0) throw Exception('You are offline and no lessons are cached.');
      return [];
    }

    try {
      if (!forceRefresh && offset == 0 && _cachedLessons.containsKey(subjectId)) {
        debugPrint('Returning cached lessons for subject: $subjectId');
        return _cachedLessons[subjectId]!;
      }

      debugPrint('Fetching lessons for subject: $subjectId (offset: $offset, limit: $limit)');
      final data = await _supabase
          .from('lessons')
          .select('id, subject_id, title_en, title_fr, title_ar, video_url, pdf_url, duration, order_number, created_at')
          .eq('subject_id', subjectId)
          .order('order_number', ascending: true)
          .range(offset, offset + limit - 1);
          
      debugPrint('Lessons fetched successfully: ${data.length} items');
      final newLessons = (data as List).map((json) => LessonModel.fromJson(json)).toList();
      
      if (offset == 0) {
        _cachedLessons[subjectId] = newLessons;
      } else {
        final existing = _cachedLessons[subjectId] ?? [];
        existing.addAll(newLessons);
        _cachedLessons[subjectId] = existing;
      }
      
      // Update Hive cache
      final encoded = jsonEncode(_cachedLessons[subjectId]!.map((l) => l.toJson()).toList());
      await box.put(cacheKey, encoded);
      
      return newLessons;
    } catch (e) {
      debugPrint('Error fetching lessons: $e');
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final allLessons = decoded.map((json) => LessonModel.fromJson(json as Map<String, dynamic>)).toList();
        final end = (offset + limit > allLessons.length) ? allLessons.length : offset + limit;
        if (offset >= allLessons.length) return [];
        return allLessons.sublist(offset, end);
      }
      throw Exception('Failed to fetch lessons: $e');
    }
  }

  /// Next lesson in the same subject by [order_number], or `null` if this is the last.
  Future<LessonModel?> getNextLesson(String subjectId, int currentOrderNumber) async {
    try {
      final data = await _supabase
          .from('lessons')
          .select('id, subject_id, title_en, title_fr, title_ar, video_url, duration, order_number, created_at, pdf_url')
          .eq('subject_id', subjectId)
          .gt('order_number', currentOrderNumber)
          .order('order_number', ascending: true)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return LessonModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching next lesson: $e');
      throw Exception('Failed to fetch next lesson: $e');
    }
  }

  /// Fetch a single lesson by its ID.
  Future<LessonModel> getLessonById(String lessonId) async {
    try {
      final data = await _supabase
          .from('lessons')
          .select('id, subject_id, title_en, title_fr, title_ar, video_url, duration, order_number, created_at')
          .eq('id', lessonId)
          .maybeSingle();
          
      if (data == null) {
        throw Exception('Lesson not found.');
      }
      return LessonModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch lesson: $e');
    }
  }
}
