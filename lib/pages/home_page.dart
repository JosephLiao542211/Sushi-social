import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;

  // Live list of sessions the user can see (enforced by RLS).
  late final Stream<List<Map<String, dynamic>>> _sessionsStream = _supabase
      .from('sessions')
      .stream(primaryKey: ['id'])
      .order('started_at', ascending: false);

  // Resolved location names, keyed by location_id. Lazy-filled.
  final Map<String, String> _locationNames = {};

  Future<void> _syncLocationNames(List<Map<String, dynamic>> sessions) async {
    final missing = sessions
        .map((s) => s['location_id'] as String?)
        .whereType<String>()
        .where((id) => !_locationNames.containsKey(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    try {
      final rows = await _supabase
          .from('locations')
          .select('id, name')
          .inFilter('id', missing);
      if (!mounted) return;
      setState(() {
        for (final row in rows) {
          _locationNames[row['id'] as String] = row['name'] as String;
        }
      });
    } catch (_) {
      // Non-fatal: a missing location just shows no subtitle.
    }
  }

  Future<void> _createSession() async {
    final result = await showDialog<_CreateSessionResult>(
      context: context,
      builder: (_) => const _CreateSessionDialog(),
    );
    if (result == null) return;

    try {
      String? locationId;
      final locName = result.locationName.trim();
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
            'name': result.name.trim().isEmpty ? null : result.name.trim(),
          })
          .select('id')
          .single();

      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SessionPage(sessionId: row['id'] as String),
      ));
    } on PostgrestException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Could not create session: $e');
    }
  }

  Future<void> _joinSession() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinSessionDialog(),
    );
    if (code == null || code.trim().isEmpty) return;
    try {
      final sessionId = await _supabase.rpc(
        'join_session_by_code',
        params: {'p_code': code.trim().toUpperCase()},
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SessionPage(sessionId: sessionId as String),
      ));
    } on PostgrestException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d $h:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍣 Sushi Social'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _supabase.auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _sessionsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          // Fire and forget — fills in location names progressively.
          _syncLocationNames(sessions);

          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🍱', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'No sessions yet.\nStart one or join with a code.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final s = sessions[i];
              final active = s['status'] == 'active';
              final locId = s['location_id'] as String?;
              final locName =
                  locId == null ? null : _locationNames[locId];
              final started = s['started_at'] as String?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: active
                      ? Colors.green.shade100
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    active ? Icons.restaurant : Icons.history,
                    color: active ? Colors.green.shade800 : Colors.grey,
                  ),
                ),
                title: Text(
                  (s['name'] as String?)?.isNotEmpty == true
                      ? s['name'] as String
                      : 'AYCE Session',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (locName != null) Text('📍 $locName'),
                    Text(
                      '${active ? "Active" : "Ended"} • Code ${s['join_code']}'
                      '${started != null ? " • ${_formatDate(started)}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SessionPage(sessionId: s['id'] as String),
                )),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: _joinSession,
            icon: const Icon(Icons.group_add),
            label: const Text('Join'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new',
            onPressed: _createSession,
            icon: const Icon(Icons.add),
            label: const Text('New session'),
          ),
        ],
      ),
    );
  }
}

class _CreateSessionResult {
  final String name;
  final String locationName;
  const _CreateSessionResult(this.name, this.locationName);
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog();
  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _name = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New AYCE session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Session name (optional)',
              hintText: 'Friday night sushi',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Restaurant (optional)',
              hintText: 'Sushi Zanmai',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _CreateSessionResult(_name.text, _location.text),
          ),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _JoinSessionDialog extends StatefulWidget {
  const _JoinSessionDialog();
  @override
  State<_JoinSessionDialog> createState() => _JoinSessionDialogState();
}

class _JoinSessionDialogState extends State<_JoinSessionDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a session'),
      content: TextField(
        controller: _code,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Join code',
          hintText: 'e.g. A7K2XP',
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_code.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_code.text),
          child: const Text('Join'),
        ),
      ],
    );
  }
}
