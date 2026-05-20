import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/authentication/data/supabase_auth_repository.dart';
import '../../data/notifications_repository.dart';
import '../../domain/models/notification_model.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

/// Realtime-enabled notifications provider.
/// Fetches initial list from DB, then listens for INSERT events via Supabase Realtime.
final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<NotificationModel>> build() async {
    final repo = ref.watch(notificationsRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) return [];

    final notifications = await repo.getNotificationsForUser(user.id);

    // Subscribe to realtime INSERT events
    _subscribeToRealtime(user.id);

    // Clean up channel when provider is disposed
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    return notifications;
  }

  void _subscribeToRealtime(String userId) {
    final supabase = Supabase.instance.client;

    _channel = supabase
        .channel('notifications_realtime_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isEmpty) return;

            final notification = NotificationModel.fromJson(newRecord);

            // Prepend new notification to the top of the list
            final current = state.valueOrNull ?? [];
            state = AsyncData([notification, ...current]);
          },
        )
        .subscribe();
  }
}

/// Unread count — derived from the realtime notifications list.
/// Updates instantly when a new notification arrives via Supabase Realtime.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);

  return notificationsAsync.when(
    data: (notifications) =>
        notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
