import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import '../../data/realtime_repository.dart';
import '../../domain/live_activity_model.dart';

final realtimeRepositoryProvider = Provider<RealtimeRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RealtimeRepository(supabase);
});

class LiveActivityNotifier extends AutoDisposeNotifier<List<LiveActivityModel>> {
  @override
  List<LiveActivityModel> build() {
    final repo = ref.watch(realtimeRepositoryProvider);
    
    // Begin listening to postgres hooks
    final subscription = repo.getLiveActivityStream().listen((activity) {
      // Prepend maintaining a strict array cap of 20 live elements
      state = [activity, ...state].take(20).toList();
    });
    
    // Safely unsubscribe the channel listeners on widget dispose explicitly mitigating memory leaks
    ref.onDispose(() {
      subscription.cancel();
    });
    
    return []; // State array initialized empty on mount
  }
}

final realtimeProvider = NotifierProvider.autoDispose<LiveActivityNotifier, List<LiveActivityModel>>(() {
  return LiveActivityNotifier();
});
