import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/courses/data/progress_repository.dart';

// Provides the Stream of ConnectivityResult list (connectivity_plus v6.0.0+)
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// A convenient provider that calculated whether the device is currently entirely offline
final isOfflineProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(connectivityStreamProvider);
  
  return connectivityState.when(
    data: (results) {
      // If the list is empty, or only contains 'none', we are offline
      if (results.isEmpty) return true;
      return results.every((element) => element == ConnectivityResult.none);
    },
    loading: () => false, // Assume online while checking momentarily to avoid flash of offline UI
    error: (_, __) => true, // Assume offline on error
  );
});

// Helper for initial check
final initialConnectivityProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  if (results.isEmpty) return true;
  return results.every((element) => element == ConnectivityResult.none);
});

// Sync offline progress when connection is restored
final syncOfflineProgressProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<ConnectivityResult>>>(
    connectivityStreamProvider,
    (previous, next) {
      next.whenData((results) {
        final isOffline = results.isEmpty || results.every((element) => element == ConnectivityResult.none);
        if (!isOffline) {
          final progressRepo = ref.read(progressRepositoryProvider);
          progressRepo.syncOfflineProgress();
        }
      });
    },
  );
});
