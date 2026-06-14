import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nexora_academy/features/courses/domain/models/subject_model.dart';

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  return SubjectsRepository(Supabase.instance.client);
});

class SubjectsRepository {
  final SupabaseClient _supabase;

  SubjectsRepository(this._supabase);

  String _mapLevelId(String rawId) {
    switch (rawId) {
      case 'high_1':
      case 'common_core':
        return 'tc';
      case 'high_2':
      case 'first_bac':
        return '1bac';
      case 'high_3':
      case 'second_bac':
        return '2bac';
      default:
        return rawId;
    }
  }

  Future<List<SubjectModel>> getSubjectsByLevel(String rawLevelId, {String? streamId, String? optionLang}) async {
    final levelId = _mapLevelId(rawLevelId);
    print("LEVEL ID = $levelId, STREAM ID = $streamId, OPTION_LANG = $optionLang");
    print('DEBUG getSubjectsByLevel: filtering subjects where level_id = "$levelId"');

    try {
      var query = _supabase.from('subjects').select();

      if (streamId != null) {
        query = query.eq('stream_id', streamId);
      } else {
        query = query.eq('level_id', levelId)..filter('stream_id', 'is', null);
      }

      if (optionLang != null) {
        query = query.or(
          'option_lang.eq.$optionLang,option_lang.is.null',
        );
      }

      final response = await query;

      print("RESPONSE = $response");
      final rawList = response as List<dynamic>;
      print('DEBUG getSubjectsByLevel: found ${rawList.length} subjects');

      return rawList
          .map<SubjectModel>((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      print('DEBUG ERROR getSubjectsByLevel: $e');
      print('Stacktrace: $stack');
      return [];
    }
  }

  Future<List<SubjectModel>> getSubjectsByLevelPaginated(
    String rawLevelId, {
    String? streamId,
    String? optionLang,
    required int page,
    int pageSize = 20,
  }) async {
    final levelId = _mapLevelId(rawLevelId);
    final from = page * pageSize;
    final to = from + pageSize - 1;

    try {
      var query = _supabase.from('subjects').select();

      if (streamId != null) {
        query = query.eq('stream_id', streamId);
      } else {
        query = query.eq('level_id', levelId)..filter('stream_id', 'is', null);
      }

      if (optionLang != null) {
        query = query.or('option_lang.eq.$optionLang,option_lang.is.null');
      }

      final response = await query.range(from, to);
      final rawList = response as List<dynamic>;

      return rawList
          .map<SubjectModel>((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      print('DEBUG ERROR getSubjectsByLevelPaginated: $e');
      print('Stacktrace: $stack');
      rethrow;
    }
  }
}
