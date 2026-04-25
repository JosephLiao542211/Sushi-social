class SessionParticipant {
  final String id;
  final String userId;
  final String sessionId;
  final int plateCount;

  const SessionParticipant({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.plateCount,
  });

  factory SessionParticipant.fromMap(Map<String, dynamic> m) =>
      SessionParticipant(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        sessionId: m['session_id'] as String,
        plateCount: (m['plate_count'] as int?) ?? 0,
      );
}
