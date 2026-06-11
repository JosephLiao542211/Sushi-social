import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/feed_controller.dart';
import '../model/social_post.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _controller = FeedController();
  late Future<List<SocialPost>> _feedFuture = _controller.fetchFeed();

  Future<void> _refresh() async {
    final nextFeed = _controller.fetchFeed();
    setState(() {
      _feedFuture = nextFeed;
    });
    await _feedFuture;
  }

  Future<void> _createPost() async {
    final result = await showDialog<_PostDraft>(
      context: context,
      builder: (_) => const _CreatePostDialog(),
    );
    if (result == null) return;

    try {
      await _controller.createPost(
        photo: result.photo,
        caption: result.caption,
        plateCount: result.plateCount,
        locationName: result.locationName,
      );
      await _refresh();
    } on PostgrestException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Could not create post: $e');
    }
  }

  Future<void> _toggleLike(SocialPost post) async {
    try {
      await _controller.toggleLike(post);
      await _refresh();
    } on PostgrestException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _comment(SocialPost post) async {
    final body = await showDialog<String>(
      context: context,
      builder: (_) => _CommentDialog(post: post),
    );
    if (body == null || body.trim().isEmpty) return;

    try {
      await _controller.addComment(postId: post.id, body: body);
      await _refresh();
    } on PostgrestException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SocialPost>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedError(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!;
        final leaderboard = _leaderboardFrom(posts);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _FeedHeader(
                    entries: leaderboard,
                    onCreatePost: _createPost,
                  ),
                ),
              ),
              if (posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyFeed(onCreatePost: _createPost),
                )
              else
                SliverList.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 4 : 0,
                      16,
                      index == posts.length - 1 ? 24 : 0,
                    ),
                    child: _PostCard(
                      post: posts[index],
                      onLike: () => _toggleLike(posts[index]),
                      onComment: () => _comment(posts[index]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<LeaderboardEntry> _leaderboardFrom(List<SocialPost> posts) {
    final sorted = [...posts]..sort((a, b) => b.plates.compareTo(a.plates));
    return sorted
        .take(8)
        .map(
          (post) => LeaderboardEntry(
            name: post.name,
            place: post.place ?? 'Unknown spot',
            plates: post.plates,
            imageUrl: post.imageUrl,
          ),
        )
        .toList();
  }
}

class _FeedHeader extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final VoidCallback onCreatePost;

  const _FeedHeader({required this.entries, required this.onCreatePost});

  @override
  Widget build(BuildContext context) {
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
            FilledButton.icon(
              onPressed: onCreatePost,
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Post'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Leaderboard(entries: entries),
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

    if (entries.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No records yet. Upload the first sushi photo to start the leaderboard.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return SizedBox(
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
  });

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
            leading: CircleAvatar(
              backgroundImage: post.avatarUrl == null
                  ? NetworkImage(post.imageUrl)
                  : NetworkImage(post.avatarUrl!),
            ),
            title: Text(
              post.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              post.place == null
                  ? post.handle
                  : '${post.handle} at ${post.place}',
            ),
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
                const Spacer(),
                IconButton(
                  tooltip: post.likedByMe ? 'Unlike' : 'Like',
                  onPressed: onLike,
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
                IconButton(
                  tooltip: 'Comment',
                  onPressed: onComment,
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
                if (post.caption.isNotEmpty) Text(post.caption),
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

class _CreatePostDialog extends StatefulWidget {
  const _CreatePostDialog();

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _locationName = TextEditingController();
  final _caption = TextEditingController();
  final _plates = TextEditingController(text: '0');
  final _picker = ImagePicker();
  XFile? _photo;
  String? _photoError;

  @override
  void dispose() {
    _locationName.dispose();
    _caption.dispose();
    _plates.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() {
      _photo = picked;
      _photoError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New feed post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_photo == null ? 'Choose photo' : _photo!.name),
            ),
            if (_photoError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _photoError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationName,
              decoration: const InputDecoration(
                labelText: 'Sushi place',
                hintText: 'Kibo Sushi House',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plates,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Plate count'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Caption'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final photo = _photo;
            if (photo == null) {
              setState(() => _photoError = 'Choose a photo to upload.');
              return;
            }
            Navigator.of(context).pop(
              _PostDraft(
                photo: photo,
                locationName: _locationName.text,
                caption: _caption.text,
                plateCount: int.tryParse(_plates.text) ?? 0,
              ),
            );
          },
          child: const Text('Post'),
        ),
      ],
    );
  }
}

class _CommentDialog extends StatefulWidget {
  final SocialPost post;

  const _CommentDialog({required this.post});

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Comment on ${widget.post.name}'),
      content: TextField(
        controller: _comment,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Comment'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_comment.text),
          child: const Text('Comment'),
        ),
      ],
    );
  }
}

class _PostDraft {
  final XFile photo;
  final String locationName;
  final String caption;
  final int plateCount;

  const _PostDraft({
    required this.photo,
    required this.locationName,
    required this.caption,
    required this.plateCount,
  });
}

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onCreatePost;

  const _EmptyFeed({required this.onCreatePost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined, size: 48),
            const SizedBox(height: 12),
            Text('No posts yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Choose a sushi photo from your device to start the feed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreatePost,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Create post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FeedError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
