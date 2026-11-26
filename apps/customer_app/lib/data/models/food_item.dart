import 'package:equatable/equatable.dart';

import 'food_category.dart';

/// Spice preference for an item (SRS FR-C03 — "spicy level / special note").
enum SpiceLevel { low, medium, high }

extension SpiceLevelX on SpiceLevel {
  String get labelBn => switch (this) {
        SpiceLevel.low => 'কম ঝাল',
        SpiceLevel.medium => 'মাঝারি ঝাল',
        SpiceLevel.high => 'বেশি ঝাল',
      };
}

/// A purchasable variation of an item — e.g. biryani "১:২ সেট" (+৳140)
/// or cake "২ পাউন্ড" (+৳500). [priceDelta] is added to the base price.
class FoodVariant extends Equatable {
  const FoodVariant({required this.label, this.priceDelta = 0});

  final String label;
  final int priceDelta;

  factory FoodVariant.fromJson(Map<String, dynamic> json) {
    return FoodVariant(
      label: json['label'] as String,
      priceDelta: (json['price_delta'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'price_delta': priceDelta,
      };

  @override
  List<Object?> get props => <Object?>[label, priceDelta];
}

/// A single menu item. All money is stored as whole BDT (int) — menus in
/// Birganj are priced in full taka, and integer math keeps totals exact.
class FoodItem extends Equatable {
  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.variants = const <FoodVariant>[],
    this.spiceCustomizable = false,
    this.isAvailable = true,
    this.noteHint,
  });

  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final int price;
  final FoodCategory category;
  final String? imageUrl;
  final List<FoodVariant> variants;

  /// Whether the spice-level selector applies (false for cakes/sweets).
  final bool spiceCustomizable;

  /// Kitchen stock toggle (Restaurant App "Stock Out" mirrors this).
  final bool isAvailable;

  /// Contextual placeholder for the special-note field,
  /// e.g. "কেকের গায়ে নাম লিখুন…".
  final String? noteHint;

  bool get hasOptions =>
      variants.isNotEmpty || spiceCustomizable || noteHint != null;

  int unitPrice({FoodVariant? variant}) => price + (variant?.priceDelta ?? 0);

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num).toInt(),
      category: FoodCategory.values.firstWhere(
        (FoodCategory c) => c.name == json['category'],
        orElse: () => FoodCategory.biryani,
      ),
      imageUrl: json['image_url'] as String?,
      variants: ((json['variants'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) => FoodVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      spiceCustomizable: (json['spice_customizable'] as bool?) ?? false,
      isAvailable: (json['is_available'] as bool?) ?? true,
      noteHint: json['note_hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'category': category.name,
        'image_url': imageUrl,
        'variants': variants.map((FoodVariant v) => v.toJson()).toList(),
        'spice_customizable': spiceCustomizable,
        'is_available': isAvailable,
        'note_hint': noteHint,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        restaurantId,
        name,
        description,
        price,
        category,
        imageUrl,
        variants,
        spiceCustomizable,
        isAvailable,
        noteHint,
      ];
}
