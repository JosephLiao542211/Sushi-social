class FriendSession {
  final String sessionId;
  final String? sessionName;
  final String hostId;
  final String hostUsername;
  final String hostName;
  final String? hostAvatarUrl;
  final String? locationName;
  final DateTime startedAt;
  final int participantCount;

  const FriendSession({
    required this.sessionId,
    required this.sessionName,
    required this.hostId,
    required this.hostUsername,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.locationName,
    required this.startedAt,
    required this.participantCount,
  });

  factory FriendSession.fromMap(Map<String, dynamic> map) {
    return FriendSession(
      sessionId: map['session_id'] as String,
      sessionName: map['session_name'] as String?,
      hostId: map['host_id'] as String,
      hostUsername: map['host_username'] as String,
      hostName: map['host_name'] as String,
      hostAvatarUrl: map['host_avatar_url'] as String?,
      locationName: map['location_name'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      participantCount: map['participant_count'] as int? ?? 1,
    );
  }

  String get title =>
      sessionName?.trim().isNotEmpty == true ? sessionName!.trim() : hostName;

  String get subtitle {
    final place = locationName?.trim();
    if (place != null && place.isNotEmpty) return place;
    return '@$hostUsername';
  }
}
