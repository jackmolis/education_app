import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/home_assignment_model.dart';

/// Home assignments for a subject (student-facing).
final homeAssignmentsProvider =
    FutureProvider.family<List<HomeAssignmentModel>, String>(
        (ref, subjectId) async {
  try {
    final data = await Supabase.instance.client
        .from('home_assignments')
        .select(
          'id, subject_id, title_en, title_fr, title_ar, '
          'description_en, description_fr, description_ar, '
          'pdf_url, order_number, created_at',
        )
        .eq('subject_id', subjectId)
        .order('order_number', ascending: true);

    return (data as List)
        .map((json) =>
            HomeAssignmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch home assignments: $e');
  }
});
