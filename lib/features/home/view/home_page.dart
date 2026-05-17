import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controller/home_controller.dart';
import '../model/session.dart';
import '../../session/view/session_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = HomeController();
  final Map<String, String> _locationNames = {};

  Future<void> _syncLocationNames(List<Session> sessions) async {
    final missing = sessions
        .map((s) => s.locationId)
        .whereType<String>()
        .where((id) => !_locationNames.containsKey(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    try {
      final fetched = await _controller.fetchLocationNames(missing);
      if (!mounted) return;
      setState(() => _locationNames.addAll(fetched));
    } catch (_) {}
  }

  Future<void> _createSession() async {
    final result = await showDialog<_CreateSessionResult>(
      context: context,
      builder: (_) => const _CreateSessionDialog(),
    );
    if (result == null) return;
    try {
      final sessionId = await _controller.createSession(
        name: result.name,
        locationName: result.locationName,
      );
      if (!mounted) return;
      _goToSession(sessionId);
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
      final sessionId = await _controller.joinSession(code);
      if (!mounted) return;
      _goToSession(sessionId);
    } on PostgrestException catch (e) {
      _snack(e.message);
    }
  }

  void _goToSession(String sessionId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SessionPage(sessionId: sessionId),
    ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime? dt) {
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
        title: const Text('🍣 Sushi Social ssahdhashdashdhahsdhashdha'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _controller.signOut,
          ),
        ],
      ),
      body: StreamBuilder<List<Session>>(
        stream: _controller.sessionsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
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
              final locName =
                  s.locationId != null ? _locationNames[s.locationId] : null;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: s.isActive
                      ? Colors.green.shade100
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    s.isActive ? Icons.restaurant : Icons.history,
                    color: s.isActive ? Colors.green.shade800 : Colors.grey,
                  ),
                ),
                title: Text(
                  s.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (locName != null) Text('📍 $locName'),
                    Text(
                      '${s.isActive ? "Active" : "Ended"} • Code ${s.joinCode}'
                      '${s.startedAt != null ? " • ${_formatDate(s.startedAt)}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _goToSession(s.id),
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
