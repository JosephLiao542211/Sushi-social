class SocialPost {
  final String name;
  final String handle;
  final String place;
  final String timeAgo;
  final String imageUrl;
  final int plates;
  final int record;
  final String caption;
  final int likes;
  final int comments;

  const SocialPost({
    required this.name,
    required this.handle,
    required this.place,
    required this.timeAgo,
    required this.imageUrl,
    required this.plates,
    required this.record,
    required this.caption,
    required this.likes,
    required this.comments,
  });
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

const socialPosts = [
  SocialPost(
    name: 'Maya Chen',
    handle: '@maki_maya',
    place: 'Kibo Sushi House',
    timeAgo: '12m',
    imageUrl:
        'https://images.unsplash.com/photo-1617196034183-421b4917c92d?auto=format&fit=crop&w=1200&q=80',
    plates: 47,
    record: 47,
    caption: 'New house record. Salmon nigiri carried the final stretch.',
    likes: 128,
    comments: 18,
  ),
  SocialPost(
    name: 'Theo Park',
    handle: '@rolltheo',
    place: 'Miku Roll Bar',
    timeAgo: '34m',
    imageUrl:
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=1200&q=80',
    plates: 41,
    record: 44,
    caption: 'Clean run, no wasted plates, spicy tuna stayed undefeated.',
    likes: 91,
    comments: 11,
  ),
  SocialPost(
    name: 'Jules Rivera',
    handle: '@jules_vs_ayce',
    place: 'Sakura AYCE',
    timeAgo: '1h',
    imageUrl:
        'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=1200&q=80',
    plates: 58,
    record: 58,
    caption: 'Leaderboard reset. Still thinking about the dragon rolls.',
    likes: 214,
    comments: 32,
  ),
];

const leaderboard = [
  LeaderboardEntry(
    name: 'Jules',
    place: 'Sakura AYCE',
    plates: 58,
    imageUrl:
        'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=300&q=80',
  ),
  LeaderboardEntry(
    name: 'Maya',
    place: 'Kibo Sushi House',
    plates: 47,
    imageUrl:
        'https://images.unsplash.com/photo-1617196034183-421b4917c92d?auto=format&fit=crop&w=300&q=80',
  ),
  LeaderboardEntry(
    name: 'Theo',
    place: 'Miku Roll Bar',
    plates: 44,
    imageUrl:
        'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=300&q=80',
  ),
  LeaderboardEntry(
    name: 'Priya',
    place: 'Nori Social',
    plates: 36,
    imageUrl:
        'https://images.unsplash.com/photo-1583623025817-d180a2221d0a?auto=format&fit=crop&w=300&q=80',
  ),
];
