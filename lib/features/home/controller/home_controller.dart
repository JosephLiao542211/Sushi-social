import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/service/oauth_service.dart';
import '../model/session.dart' as home_model;

class HomeController {
  final _supabase = Supabase.instance.client;
  final _oauthService = OAuthService.instance;

  Stream<List<home_model.Session>> get sessionsStream => _supabase
      .from('sessions')
      .stream(primaryKey: ['id'])
      .order('started_at', ascending: false)
      .map((rows) => rows.map(home_model.Session.fromMap).toList());

  Future<Map<String, String>> fetchLocationNames(List<String> ids) async {
    final rows = await _supabase
        .from('locations')
        .select('id, name')
        .inFilter('id', ids);
    return {for (final row in rows) row['id'] as String: row['name'] as String};
  }

  Future<String> createSession({
    required String name,
    required String locationName,
  }) async {
    String? locationId;
    final locName = locationName.trim();
    if (locName.isNotEmpty) {
      final existing = await _supabase
          .from('locations')
          .select('id')
          .ilike('name', locName)
          .maybeSingle();
      if (existing != null) {
        locationId = existing['id'] as String;
      } else {
        final inserted = await _supabase
            .from('locations')
            .insert({'name': locName})
            .select('id')
            .single();
        locationId = inserted['id'] as String;
      }
    }

    final row = await _supabase
        .from('sessions')
        .insert({
          'location_id': locationId,
          'name': name.trim().isEmpty ? null : name.trim(),
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<String> joinSession(String code) async {
    final id = await _supabase.rpc(
      'join_session_by_code',
      params: {'p_code': code.trim().toUpperCase()},
    );
    return id as String;
  }

  void signOut() => _oauthService.signOut();
}
