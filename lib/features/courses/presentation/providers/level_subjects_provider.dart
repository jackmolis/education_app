import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/level_subject_model.dart';

/// Mock data provider for subjects by level.
/// Will be replaced with Supabase query:
///   SELECT * FROM subjects WHERE level_id = ?
final subjectsByLevelProvider =
    FutureProvider.family<List<LevelSubject>, String>((ref, levelId) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 600));

  final allSubjects = <String, List<Map<String, String>>>{
    // Primary
    'primary_1': [
      {'id': 'p1_math', 'name': 'Math'},
      {'id': 'p1_arabic', 'name': 'Arabic'},
      {'id': 'p1_french', 'name': 'French'},
    ],
    'primary_2': [
      {'id': 'p2_math', 'name': 'Math'},
      {'id': 'p2_arabic', 'name': 'Arabic'},
      {'id': 'p2_french', 'name': 'French'},
    ],
    'primary_3': [
      {'id': 'p3_math', 'name': 'Math'},
      {'id': 'p3_arabic', 'name': 'Arabic'},
      {'id': 'p3_french', 'name': 'French'},
      {'id': 'p3_science', 'name': 'Science'},
    ],
    'primary_4': [
      {'id': 'p4_math', 'name': 'Math'},
      {'id': 'p4_arabic', 'name': 'Arabic'},
      {'id': 'p4_french', 'name': 'French'},
      {'id': 'p4_science', 'name': 'Science'},
    ],
    'primary_5': [
      {'id': 'p5_math', 'name': 'Math'},
      {'id': 'p5_arabic', 'name': 'Arabic'},
      {'id': 'p5_french', 'name': 'French'},
      {'id': 'p5_science', 'name': 'Science'},
    ],
    'primary_6': [
      {'id': 'p6_math', 'name': 'Math'},
      {'id': 'p6_arabic', 'name': 'Arabic'},
      {'id': 'p6_french', 'name': 'French'},
      {'id': 'p6_science', 'name': 'Science'},
    ],
    // Middle School
    'middle_1': [
      {'id': 'm1_math', 'name': 'Math'},
      {'id': 'm1_physics', 'name': 'Physics'},
      {'id': 'm1_svt', 'name': 'SVT'},
      {'id': 'm1_arabic', 'name': 'Arabic'},
      {'id': 'm1_french', 'name': 'French'},
    ],
    'middle_2': [
      {'id': 'm2_math', 'name': 'Math'},
      {'id': 'm2_physics', 'name': 'Physics'},
      {'id': 'm2_svt', 'name': 'SVT'},
      {'id': 'm2_arabic', 'name': 'Arabic'},
      {'id': 'm2_french', 'name': 'French'},
    ],
    'middle_3': [
      {'id': 'm3_math', 'name': 'Math'},
      {'id': 'm3_physics', 'name': 'Physics'},
      {'id': 'm3_svt', 'name': 'SVT'},
      {'id': 'm3_arabic', 'name': 'Arabic'},
      {'id': 'm3_french', 'name': 'French'},
      {'id': 'm3_english', 'name': 'English'},
    ],
    // High School
    'high_1': [
      {'id': 'h1_math', 'name': 'Math'},
      {'id': 'h1_physics', 'name': 'Physics & Chemistry'},
      {'id': 'h1_svt', 'name': 'SVT'},
      {'id': 'h1_arabic', 'name': 'Arabic'},
      {'id': 'h1_french', 'name': 'French'},
      {'id': 'h1_english', 'name': 'English'},
      {'id': 'h1_philosophy', 'name': 'Philosophy'},
    ],
    'high_2': [
      {'id': 'h2_math', 'name': 'Math'},
      {'id': 'h2_physics', 'name': 'Physics & Chemistry'},
      {'id': 'h2_svt', 'name': 'SVT'},
      {'id': 'h2_arabic', 'name': 'Arabic'},
      {'id': 'h2_french', 'name': 'French'},
      {'id': 'h2_english', 'name': 'English'},
      {'id': 'h2_philosophy', 'name': 'Philosophy'},
    ],
    'high_3': [
      {'id': 'h3_math', 'name': 'Math'},
      {'id': 'h3_physics', 'name': 'Physics & Chemistry'},
      {'id': 'h3_svt', 'name': 'SVT'},
      {'id': 'h3_arabic', 'name': 'Arabic'},
      {'id': 'h3_french', 'name': 'French'},
      {'id': 'h3_english', 'name': 'English'},
      {'id': 'h3_philosophy', 'name': 'Philosophy'},
    ],
  };

  final subjects = allSubjects[levelId] ?? [];

  return subjects
      .map((s) => LevelSubject(
            id: s['id']!,
            name: s['name']!,
            levelId: levelId,
          ))
      .toList();
});
