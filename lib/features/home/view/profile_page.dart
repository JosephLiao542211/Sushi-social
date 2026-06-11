import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final displayName =
        (metadata['display_name'] ?? metadata['username'] ?? 'Sushi fan')
            .toString();
    final email = user?.email ?? 'Signed in';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              child: Text(
                displayName.isEmpty ? 'S' : displayName[0].toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _StatsGrid(),
        const SizedBox(height: 20),
        Text(
          'Badges',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const _BadgeTile(
          icon: Icons.emoji_events,
          title: 'Local champion',
          subtitle: 'Held a restaurant record this week',
        ),
        const _BadgeTile(
          icon: Icons.local_fire_department,
          title: 'Hot streak',
          subtitle: 'Three sessions in seven days',
        ),
        const _BadgeTile(
          icon: Icons.groups,
          title: 'Table captain',
          subtitle: 'Hosted five group sessions',
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: const [
        _StatTile(label: 'Personal record', value: '47'),
        _StatTile(label: 'Total plates', value: '312'),
        _StatTile(label: 'Sessions', value: '14'),
        _StatTile(label: 'Rank', value: '#2'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BadgeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}
