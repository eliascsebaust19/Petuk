import 'package:equatable/equatable.dart';

import 'food_item.dart';

/// One line in the cart.
///
/// Identity rule: same food + same variant + same spice level + same note
/// merges into a single line (quantity increases). Any difference creates
/// a separate line, so "কম ঝাল" and "বেশি ঝাল" biryanis coexist correctly.
class CartItem extends Equatable {
  const CartItem({
    required this.food,
    this.variant,
    this.spice,
    this.note = '',
    this.quantity = 1,
  });

  final FoodItem food;
  final FoodVariant? variant;
  final SpiceLevel? spice;
  final String note;
  final int quantity;

  String get restaurantId => food.restaurantId;

  int get unitPrice => food.unitPrice(variant: variant);

  int get lineTotal => unitPrice * quantity;

  /// Stable merge key for the identity rule above.
  String get key =>
      '${food.id}|${variant?.label ?? ''}|${spice?.name ?? ''}|${note.trim()}';

  /// Human-readable options line, e.g. `১:২ সেট • বেশি ঝাল • "পেঁয়াজ কম"`.
  String get optionsLabel {
    final List<String> parts = <String>[
      if (variant != null) variant!.label,
      if (spice != null) spice!.labelBn,
      if (note.trim().isNotEmpty) '“${note.trim()}”',
    ];
    return parts.join(' • ');
  }

  CartItem copyWith({int? quantity}) => CartItem(
        food: food,
        variant: variant,
        spice: spice,
        note: note,
        quantity: quantity ?? this.quantity,
      );

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? variantJson =
        json['variant'] as Map<String, dynamic>?;
    final String? spiceName = json['spice'] as String?;
    return CartItem(
      food: FoodItem.fromJson(json['food'] as Map<String, dynamic>),
      variant:
          variantJson == null ? null : FoodVariant.fromJson(variantJson),
      spice: spiceName == null
          ? null
          : SpiceLevel.values.firstWhere(
              (SpiceLevel s) => s.name == spiceName,
              orElse: () => SpiceLevel.medium,
            ),
      note: (json['note'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'food': food.toJson(),
        'variant': variant?.toJson(),
        'spice': spice?.name,
        'note': note,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => <Object?>[food, variant, spice, note, quantity];
}
