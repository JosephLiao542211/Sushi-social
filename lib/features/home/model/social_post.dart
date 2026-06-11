class SocialPost {
  final String id;
  final String authorId;
  final String name;
  final String handle;
  final String? avatarUrl;
  final String? place;
  final DateTime createdAt;
  final String imageUrl;
  final String? photoBucket;
  final String? photoObjectPath;
  final int plates;
  final String caption;
  final int likes;
  final int comments;
  final bool likedByMe;

  const SocialPost({
    required this.id,
    required this.authorId,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.place,
    required this.createdAt,
    required this.imageUrl,
    required this.photoBucket,
    required this.photoObjectPath,
    required this.plates,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.likedByMe,
  });

  factory SocialPost.fromMap(Map<String, dynamic> map) {
    final username = map['author_username'] as String? ?? 'sushi_friend';
    return SocialPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      name: map['author_name'] as String? ?? username,
      handle: '@$username',
      avatarUrl: map['author_avatar_url'] as String?,
      place: map['location_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      imageUrl: map['photo_url'] as String,
      photoBucket: map['photo_bucket'] as String?,
      photoObjectPath: map['photo_object_path'] as String?,
      plates: map['plate_count'] as int? ?? 0,
      caption: map['caption'] as String? ?? '',
      likes: map['like_count'] as int? ?? 0,
      comments: map['comment_count'] as int? ?? 0,
      likedByMe: map['liked_by_me'] as bool? ?? false,
    );
  }

  SocialPost copyWith({String? imageUrl}) {
    return SocialPost(
      id: id,
      authorId: authorId,
      name: name,
      handle: handle,
      avatarUrl: avatarUrl,
      place: place,
      createdAt: createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      photoBucket: photoBucket,
      photoObjectPath: photoObjectPath,
      plates: plates,
      caption: caption,
      likes: likes,
      comments: comments,
      likedByMe: likedByMe,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}

class LeaderboardEntry {
  final String name;
  final String place;
  final int plates;
  final String imageUrl;

  const LeaderboardEntry({
    required this.name,
    required this.place,
    required this.plates,
    required this.imageUrl,
  });
}
