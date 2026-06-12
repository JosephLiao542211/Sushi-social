import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../session/view/session_page.dart';
import '../controller/home_controller.dart';
import '../model/location.dart';
import 'feed_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = HomeController();
  int _pageIndex = 0;

  Future<void> _startSession([SushiLocation? location]) async {
    final result = await showDialog<_CreateSessionResult>(
      context: context,
      builder: (_) => _CreateSessionDialog(location: location),
    );
    if (result == null) return;

    try {
      final sessionId = await _controller.createSession(
        name: result.name,
        locationName: result.locationName,
        locationId: result.locationId,
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionPage(sessionId: sessionId)),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FeedPage(),
      MapPage(controller: _controller, onStartSession: _startSession),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sushi Social'),
        actions: [
          IconButton(
            tooltip: 'Join session',
            onPressed: _joinSession,
            icon: const Icon(Icons.group_add_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _controller.signOut,
          ),
        ],
      ),
      body: IndexedStack(index: _pageIndex, children: pages),
      floatingActionButton: _pageIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _startSession(),
              icon: const Icon(Icons.add),
              label: const Text('New session'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (index) => setState(() => _pageIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CreateSessionResult {
  final String name;
  final String locationName;
  final String? locationId;

  const _CreateSessionResult(this.name, this.locationName, this.locationId);
}

class _CreateSessionDialog extends StatefulWidget {
  final SushiLocation? location;

  const _CreateSessionDialog({this.location});

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _name = TextEditingController();
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    _location = TextEditingController(text: widget.location?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New sushi session'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Session name',
              hintText: 'Friday night sushi',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Restaurant',
              hintText: 'Kibo Sushi House',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            _CreateSessionResult(
              _name.text,
              _location.text,
              widget.location?.id,
            ),
          ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
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
