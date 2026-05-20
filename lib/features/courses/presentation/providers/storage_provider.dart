import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/storage_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(supabase: ref.watch(supabaseClientProvider));
});

/// A generic family provider that resolves a storage path from the 'lessons' bucket
/// into a full accessible signed URL.
final lessonMediaUrlProvider = FutureProvider.family<String, String>((
  ref,
  path,
) async {
  if (path.isEmpty) return '';
  final repository = ref.watch(storageRepositoryProvider);
  return repository.getSignedUrl('lessons', path);
});
