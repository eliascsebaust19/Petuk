import 'package:equatable/equatable.dart';

import 'food_category.dart';
import 'food_item.dart';

/// Live kitchen status shown on restaurant cards (SRS FR-C02).
enum RestaurantStatus { open, busy, closed }

extension RestaurantStatusX on RestaurantStatus {
  String get labelBn => switch (this) {
        RestaurantStatus.open => 'খোলা',
        RestaurantStatus.busy => 'ব্যস্ত',
        RestaurantStatus.closed => 'বন্ধ',
      };
}

/// A Birganj restaurant with its full menu embedded.
///
/// Phase 1 ships the whole catalog in one small payload (8–10 partners),
/// which is ideal for offline caching on slow networks. The Phase 2 API
/// can keep this exact shape.
class Restaurant extends Equatable {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.landmark,
    required this.rating,
    required this.ratingCount,
    required this.etaMinutes,
    required this.distanceKm,
    required this.status,
    required this.menu,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;

  /// Short cuisine descriptor, e.g. "বিরিয়ানি • তেহারি • পোলাও".
  final String cuisine;

  /// Landmark-first location, e.g. "পাইলট স্কুলের বিপরীতে".
  final String landmark;

  final double rating;
  final int ratingCount;

  /// Estimated delivery window shown on the card (30–45 min, FR-C02).
  final int etaMinutes;
  final double distanceKm;
  final RestaurantStatus status;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final List<FoodItem> menu;

  bool get isOrderable => status != RestaurantStatus.closed;
  bool get hasCoordinates => latitude != null && longitude != null;

  Set<FoodCategory> get categories =>
      menu.map((FoodItem f) => f.category).toSet();

  FoodCategory get primaryCategory =>
      menu.isEmpty ? FoodCategory.biryani : menu.first.category;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: (json['cuisine'] as String?) ?? '',
      landmark: (json['landmark'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 40,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      status: RestaurantStatus.values.firstWhere(
        (RestaurantStatus s) => s.name == json['status'],
        orElse: () => RestaurantStatus.open,
      ),
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      menu: ((json['menu'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'cuisine': cuisine,
        'landmark': landmark,
        'rating': rating,
        'rating_count': ratingCount,
        'eta_minutes': etaMinutes,
        'distance_km': distanceKm,
        'status': status.name,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'menu': menu.map((FoodItem f) => f.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        cuisine,
        landmark,
        rating,
        ratingCount,
        etaMinutes,
        distanceKm,
        status,
        imageUrl,
        latitude,
        longitude,
        menu,
      ];
}
