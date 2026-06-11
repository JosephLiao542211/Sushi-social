class SushiLocation {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;

  const SushiLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get subtitle {
    final parts = [
      if (address?.trim().isNotEmpty == true) address!.trim(),
      if (city?.trim().isNotEmpty == true) city!.trim(),
    ];
    return parts.isEmpty ? 'No address yet' : parts.join(', ');
  }

  factory SushiLocation.fromMap(Map<String, dynamic> map) {
    return SushiLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      city: map['city'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
