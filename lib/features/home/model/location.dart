class SushiLocation {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? googlePlaceId;
  final String? formattedAddress;
  final double? rating;
  final int? userRatingCount;
  final String? priceLevel;
  final String? businessStatus;
  final String? googleMapsUri;

  const SushiLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.googlePlaceId,
    required this.formattedAddress,
    required this.rating,
    required this.userRatingCount,
    required this.priceLevel,
    required this.businessStatus,
    required this.googleMapsUri,
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
      googlePlaceId: map['google_place_id'] as String?,
      formattedAddress: map['formatted_address'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      userRatingCount: map['user_rating_count'] as int?,
      priceLevel: map['price_level'] as String?,
      businessStatus: map['business_status'] as String?,
      googleMapsUri: map['google_maps_uri'] as String?,
    );
  }
}
