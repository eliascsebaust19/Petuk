import 'package:equatable/equatable.dart';

enum CouponType { flat, percent, freeDelivery }

/// A promo coupon (marketing plan: "৳৪০ ফ্ল্যাট ছাড়", first-order free
/// delivery). Validation happens server-side in Phase 2; the rules here
/// are shared by the mock repository and the cart calculations.
class Coupon extends Equatable {
  const Coupon({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.minSubtotal = 0,
    this.maxDiscount,
  });

  final String code;
  final String description;
  final CouponType type;

  /// Flat: BDT amount. Percent: 0–100. Free delivery: ignored.
  final int value;

  /// Minimum food subtotal required for the coupon to apply.
  final int minSubtotal;

  /// Optional cap for percent coupons.
  final int? maxDiscount;

  bool appliesTo(int subtotal) => subtotal >= minSubtotal;

  /// Discount in BDT for the given bill. Never exceeds the subtotal.
  int discountFor({required int subtotal, required int deliveryFee}) {
    if (!appliesTo(subtotal)) return 0;
    final int raw = switch (type) {
      CouponType.flat => value,
      CouponType.percent => (subtotal * value / 100).round(),
      CouponType.freeDelivery => deliveryFee,
    };
    final int capped =
        maxDiscount != null && raw > maxDiscount! ? maxDiscount! : raw;
    return capped > subtotal ? subtotal : capped;
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'] as String,
      description: (json['description'] as String?) ?? '',
      type: CouponType.values.firstWhere(
        (CouponType t) => t.name == json['type'],
        orElse: () => CouponType.flat,
      ),
      value: (json['value'] as num?)?.toInt() ?? 0,
      minSubtotal: (json['min_subtotal'] as num?)?.toInt() ?? 0,
      maxDiscount: (json['max_discount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'description': description,
        'type': type.name,
        'value': value,
        'min_subtotal': minSubtotal,
        'max_discount': maxDiscount,
      };

  @override
  List<Object?> get props =>
      <Object?>[code, description, type, value, minSubtotal, maxDiscount];
}

/// Thrown when a coupon code is unknown or ineligible.
class CouponException implements Exception {
  const CouponException(this.message);

  final String message;

  @override
  String toString() => 'CouponException: $message';
}
