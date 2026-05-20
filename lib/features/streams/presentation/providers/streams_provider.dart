import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/streams_repository.dart';
import '../../domain/models/stream_model.dart';

final streamsRepositoryProvider = Provider<StreamsRepository>((ref) {
  return StreamsRepository(Supabase.instance.client);
});

final streamsByLevelProvider = FutureProvider.family<List<StreamModel>, String>((ref, levelId) async {
  final repository = ref.read(streamsRepositoryProvider);
  return repository.getStreamsByLevel(levelId);
});
