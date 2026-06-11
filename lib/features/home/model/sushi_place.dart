class SushiPlace {
  final String name;
  final String area;
  final String distance;
  final String price;
  final double rating;
  final int activeSessions;
  final int topRecord;
  final String topEater;
  final double x;
  final double y;

  const SushiPlace({
    required this.name,
    required this.area,
    required this.distance,
    required this.price,
    required this.rating,
    required this.activeSessions,
    required this.topRecord,
    required this.topEater,
    required this.x,
    required this.y,
  });
}

const sushiPlaces = [
  SushiPlace(
    name: 'Kibo Sushi House',
    area: 'King West',
    distance: '0.4 mi',
    price: r'$$',
    rating: 4.8,
    activeSessions: 2,
    topRecord: 47,
    topEater: 'Maya',
    x: .26,
    y: .36,
  ),
  SushiPlace(
    name: 'Miku Roll Bar',
    area: 'Harbourfront',
    distance: '0.8 mi',
    price: r'$$$',
    rating: 4.7,
    activeSessions: 1,
    topRecord: 41,
    topEater: 'Theo',
    x: .72,
    y: .28,
  ),
  SushiPlace(
    name: 'Sakura AYCE',
    area: 'Chinatown',
    distance: '1.1 mi',
    price: r'$$',
    rating: 4.5,
    activeSessions: 4,
    topRecord: 58,
    topEater: 'Jules',
    x: .42,
    y: .68,
  ),
  SushiPlace(
    name: 'Nori Social',
    area: 'The Annex',
    distance: '1.6 mi',
    price: r'$$',
    rating: 4.6,
    activeSessions: 0,
    topRecord: 36,
    topEater: 'Priya',
    x: .64,
    y: .74,
  ),
];
