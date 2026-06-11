import 'package:flutter/material.dart';

import '../model/social_post.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _Leaderboard(entries: leaderboard),
          ),
        ),
        SliverList.separated(
          itemCount: socialPosts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              index == 0 ? 4 : 0,
              16,
              index == socialPosts.length - 1 ? 24 : 0,
            ),
            child: _PostCard(post: socialPosts[index]),
          ),
        ),
      ],
    );
  }
}

class _Leaderboard extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _Leaderboard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Leaderboard',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.trending_up, size: 18),
              label: const Text('Records'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return SizedBox(
                width: 150,
                child: Card(
                  elevation: 0,
                  color: index == 0
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(entry.imageUrl),
                            ),
                            const Spacer(),
                            Text(
                              '#${index + 1}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          entry.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          entry.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.plates} plates',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final SocialPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: CircleAvatar(backgroundImage: NetworkImage(post.imageUrl)),
            title: Text(
              post.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${post.handle} at ${post.place}'),
            trailing: Text(post.timeAgo),
          ),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE8E2D6),
                child: Center(child: Icon(Icons.restaurant, size: 44)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                _Metric(icon: Icons.set_meal, label: '${post.plates} plates'),
                const SizedBox(width: 14),
                _Metric(
                  icon: Icons.emoji_events,
                  label: 'Record ${post.record}',
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Like',
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                ),
                IconButton(
                  tooltip: 'Comment',
                  onPressed: () {},
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.caption),
                const SizedBox(height: 6),
                Text(
                  '${post.likes} likes  ${post.comments} comments',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
