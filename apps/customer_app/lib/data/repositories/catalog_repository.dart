import '../models/coupon.dart';
import '../models/restaurant.dart';

/// Restaurant catalog + promo coupons (SRS FR-C02/03).
abstract interface class CatalogRepository {
  /// All partner restaurants with embedded menus (single cached payload).
  Future<List<Restaurant>> fetchRestaurants();

  /// Validates [code] and returns the coupon rules.
  ///
  /// Throws [CouponException] when the code is unknown. Minimum-subtotal
  /// eligibility is re-checked by the CartBloc on every mutation.
  Future<Coupon> validateCoupon(String code);
}
