import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/stream_model.dart';

class StreamsRepository {
  final SupabaseClient _supabase;

  StreamsRepository(this._supabase);

  Future<List<StreamModel>> getStreamsByLevel(String levelId) async {
    try {
      final response = await _supabase
          .from('streams')
          .select()
          .eq('level_id', levelId)
          .order('order_number');
          
      final rawList = response as List<dynamic>;
      return rawList
          .map((json) => StreamModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      debugPrint('Error fetching streams by level $levelId: $e\n$stack');
      return [];
    }
  }
}
