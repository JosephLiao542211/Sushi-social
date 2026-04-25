class Session {
  final String id;
  final String? name;
  final String? locationId;
  final String joinCode;
  final String status;
  final DateTime? startedAt;

  const Session({
    required this.id,
    this.name,
    this.locationId,
    required this.joinCode,
    required this.status,
    this.startedAt,
  });

  bool get isActive => status == 'active';

  String get displayName =>
      (name?.isNotEmpty == true) ? name! : 'AYCE Session';

  factory Session.fromMap(Map<String, dynamic> m) => Session(
        id: m['id'] as String,
        name: m['name'] as String?,
        locationId: m['location_id'] as String?,
        joinCode: m['join_code'] as String,
        status: m['status'] as String,
        startedAt: m['started_at'] != null
            ? DateTime.tryParse(m['started_at'] as String)?.toLocal()
            : null,
      );
}
