import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/live_activity_model.dart';

class RealtimeRepository {
  final SupabaseClient _supabaseClient;
  
  RealtimeRepository(this._supabaseClient);

  Stream<LiveActivityModel> getLiveActivityStream() {
    final streamController = StreamController<LiveActivityModel>.broadcast();
    final channel = _supabaseClient.channel('admin_live_activity');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'results',
      callback: (payload) {
        final newRecord = payload.newRecord;
        streamController.add(LiveActivityModel(
          id: newRecord['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: ActivityType.quiz,
          description: 'User completed a quiz',
          timestamp: DateTime.now(),
        ));
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'video_progress',
      callback: (payload) {
        final newRecord = payload.newRecord;
        streamController.add(LiveActivityModel(
          id: newRecord['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: ActivityType.video,
          description: 'User started a lesson',
          timestamp: DateTime.now(),
        ));
      },
    ).subscribe();

    streamController.onCancel = () {
      _supabaseClient.removeChannel(channel);
      streamController.close();
    };

    return streamController.stream;
  }
}
