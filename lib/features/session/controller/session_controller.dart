import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/session_participant.dart';

class SessionController {
  final _supabase = Supabase.instance.client;
  final String sessionId;

  SessionController(this.sessionId);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Stream<List<SessionParticipant>> get participantsStream => _supabase
      .from('session_participants')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('joined_at', ascending: true)
      .map((rows) => rows.map(SessionParticipant.fromMap).toList());

  Future<({Map<String, dynamic> session, String? locationName})>
      loadSession() async {
    final row = await _supabase
        .from('sessions')
        .select(
          'id, host_id, location_id, name, join_code, status, started_at, ended_at',
        )
        .eq('id', sessionId)
        .single();

    String? locName;
    if (row['location_id'] != null) {
      final loc = await _supabase
          .from('locations')
          .select('name')
          .eq('id', row['location_id'] as String)
          .maybeSingle();
      locName = loc?['name'] as String?;
    }

    return (session: row as Map<String, dynamic>, locationName: locName);
  }

  Future<Map<String, Map<String, dynamic>>> fetchProfiles(
      List<String> ids) async {
    final rows = await _supabase
        .from('profiles')
        .select('id, username, display_name')
        .inFilter('id', ids);
    return {
      for (final row in rows) row['id'] as String: row as Map<String, dynamic>,
    };
  }

  Future<void> increment() async {
    await _supabase.rpc(
      'increment_my_plate_count',
      params: {'p_session_id': sessionId},
    );
    HapticFeedback.selectionClick();
  }

  Future<void> decrement() async {
    await _supabase.rpc(
      'decrement_my_plate_count',
      params: {'p_session_id': sessionId},
    );
  }

  Future<void> endSession() async {
    await _supabase.from('sessions').update({
      'status': 'ended',
      'ended_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
