import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controller/session_controller.dart';
import '../model/session_participant.dart';

class SessionPage extends StatefulWidget {
  final String sessionId;
  const SessionPage({super.key, required this.sessionId});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late final _controller = SessionController(widget.sessionId);

  Map<String, dynamic>? _session;
  String? _locationName;
  bool _busy = false;
  final Map<String, Map<String, dynamic>> _profiles = {};

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final result = await _controller.loadSession();
      if (!mounted) return;
      setState(() {
        _session = result.session;
        _locationName = result.locationName;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _syncProfiles(List<SessionParticipant> participants) async {
    final missing = participants
        .map((p) => p.userId)
        .where((id) => !_profiles.containsKey(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    try {
      final fetched = await _controller.fetchProfiles(missing);
      if (!mounted) return;
      setState(() => _profiles.addAll(fetched));
    } catch (_) {}
  }

  Future<void> _increment() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _controller.increment();
    } on PostgrestException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decrement() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _controller.decrement();
    } on PostgrestException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('No one will be able to change counts after this.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _controller.endSession();
      await _loadSession();
    } on PostgrestException catch (e) {
      _snack(e.message);
    }
  }

  void _copyJoinCode(String code) {
    _controller.copyToClipboard(code);
    _snack('Code $code copied');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myId = _controller.currentUserId;
    final isHost = session['host_id'] == myId;
    final isActive = session['status'] == 'active';
    final joinCode = session['join_code'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (session['name'] as String?)?.isNotEmpty == true
              ? session['name'] as String
              : 'AYCE Session',
        ),
        actions: [
          if (isHost && isActive)
            IconButton(
              tooltip: 'End session',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: _endSession,
            ),
        ],
      ),
      body: StreamBuilder<List<SessionParticipant>>(
        stream: _controller.participantsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final participants = snapshot.data!;
          _syncProfiles(participants);

          final me = participants.firstWhere(
            (p) => p.userId == myId,
            orElse: () => SessionParticipant(
              id: '',
              userId: '',
              sessionId: widget.sessionId,
              plateCount: 0,
            ),
          );
          final myCount = me.plateCount;
          final total = participants.fold<int>(
            0,
            (acc, p) => acc + p.plateCount,
          );

          return Column(
            children: [
              _SessionHeader(
                locationName: _locationName,
                joinCode: joinCode,
                total: total,
                participantCount: participants.length,
                active: isActive,
                onCopyCode: () => _copyJoinCode(joinCode),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Sushi Count',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$myCount',
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 36,
                    onPressed: (isActive && myCount > 0) ? _decrement : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    height: 96,
                    width: 96,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: isActive ? _increment : null,
                      child: const Icon(Icons.add, size: 48),
                    ),
                  ),
                ],
              ),
              if (!isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Session ended',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Expanded(
                child: _ParticipantsList(
                  participants: participants,
                  profiles: _profiles,
                  myUserId: myId,
                  hostId: session['host_id'] as String?,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final String? locationName;
  final String joinCode;
  final int total;
  final int participantCount;
  final bool active;
  final VoidCallback onCopyCode;

  const _SessionHeader({
    required this.locationName,
    required this.joinCode,
    required this.total,
    required this.participantCount,
    required this.active,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (locationName != null)
            Text(
              '📍 $locationName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                onTap: onCopyCode,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Code: $joinCode',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 14),
                    ],
                  ),
                ),
              ),
              if (!active) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text('ENDED'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.grey.shade300,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '🍣 $total plates • $participantCount '
            '${participantCount == 1 ? 'person' : 'people'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _ParticipantsList extends StatelessWidget {
  final List<SessionParticipant> participants;
  final Map<String, Map<String, dynamic>> profiles;
  final String? myUserId;
  final String? hostId;

  const _ParticipantsList({
    required this.participants,
    required this.profiles,
    required this.myUserId,
    required this.hostId,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...participants]
      ..sort((a, b) => b.plateCount.compareTo(a.plateCount));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final p = sorted[i];
        final profile = profiles[p.userId];
        final name =
            (profile?['display_name'] as String?)?.trim().isNotEmpty == true
                ? profile!['display_name'] as String
                : (profile?['username'] as String?) ?? '…';
        final isMe = p.userId == myUserId;
        final isHost = p.userId == hostId;

        return ListTile(
          leading: CircleAvatar(
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  isMe ? '$name (you)' : name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (isHost) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, size: 14, color: Colors.amber),
              ],
            ],
          ),
          trailing: Text(
            '${p.plateCount}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        );
      },
    );
  }
}
