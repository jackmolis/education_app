import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nexora_academy/features/courses/domain/models/subject_model.dart';
import 'package:nexora_academy/features/courses/domain/models/level_model.dart';
import 'package:nexora_academy/features/courses/data/subjects_repository.dart';

// NOT autoDispose — levels rarely change and should persist across navigation.
final levelsProvider = FutureProvider<List<LevelModel>>((ref) async {
  final response = await Supabase.instance.client.from('levels').select('id, name').order('name');
  return (response as List).map((json) => LevelModel.fromJson(json as Map<String, dynamic>)).toList();
});

typedef SubjectsQueryArgs = ({String levelId, String? streamId, String? optionLang});
typedef OptionsQueryArgs = ({String levelId, String? streamId});
final optionsByLevelProvider =
FutureProvider.family<List<String>, OptionsQueryArgs>((ref, args) async {
  final supabase = Supabase.instance.client;

  var query = supabase
      .from('subjects')
      .select('option_lang')
      .eq('level_id', args.levelId);

  if (args.streamId != null) {
    query = query.eq('stream_id', args.streamId!);
  }

  final response = await query;

  final data = response as List;

  final options = data
      .map((e) => e['option_lang'] as String?)
      .where((e) => e != null && e.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();

  return options;
});

final subjectsByLevelProvider =
    FutureProvider.family<List<SubjectModel>, SubjectsQueryArgs>((ref, args) async {
  final repository = ref.read(subjectsRepositoryProvider);
  return repository.getSubjectsByLevel(args.levelId, streamId: args.streamId, optionLang: args.optionLang);
});
