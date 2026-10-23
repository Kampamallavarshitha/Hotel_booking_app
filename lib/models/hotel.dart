import 'room.dart';

class Hotel {
  final String id, name, city, state, address, description;
  final List<String> images, amenities;
  final double rating, pricePerNight;
  final int reviewCount;
  final List<Room> rooms;

  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.address,
    required this.description,
    required this.images,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    this.rooms = const [],
  });

  String get location => '$city, $state';
  String get cover => images.first;

  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(
        id: j['id'],
        name: j['name'],
        city: j['city'],
        state: j['state'],
        address: j['address'],
        description: j['description'],
        images: List<String>.from(j['images']),
        amenities: List<String>.from(j['amenities']),
        rating: (j['rating'] as num).toDouble(),
        reviewCount: j['reviewCount'],
        pricePerNight: (j['pricePerNight'] as num).toDouble(),
        rooms: ((j['rooms'] as List?) ?? []).map((e) => Room.fromJson(e)).toList(),
      );
}

/// Query object sent to `GET /hotels`.
class HotelFilters {
  final String query;
  final double minPrice, maxPrice, minRating;
  final Set<String> amenities;
  final String sort; // recommended | price_asc | price_desc | rating

  static const double priceCeiling = 20000;

  const HotelFilters({
    this.query = '',
    this.minPrice = 0,
    this.maxPrice = priceCeiling,
    this.minRating = 0,
    this.amenities = const {},
    this.sort = 'recommended',
  });

  /// Number of filters applied by the user (search text excluded).
  int get activeCount =>
      (minPrice > 0 || maxPrice < priceCeiling ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (amenities.isNotEmpty ? 1 : 0) +
      (sort != 'recommended' ? 1 : 0);

  HotelFilters copyWith({
    String? query,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    Set<String>? amenities,
    String? sort,
  }) =>
      HotelFilters(
        query: query ?? this.query,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minRating: minRating ?? this.minRating,
        amenities: amenities ?? this.amenities,
        sort: sort ?? this.sort,
      );

  Map<String, String> toQuery() => {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (minPrice > 0) 'minPrice': minPrice.round().toString(),
        if (maxPrice < priceCeiling) 'maxPrice': maxPrice.round().toString(),
        if (minRating > 0) 'minRating': minRating.toString(),
        if (amenities.isNotEmpty) 'amenities': amenities.join(','),
        if (sort != 'recommended') 'sort': sort,
      };
}
