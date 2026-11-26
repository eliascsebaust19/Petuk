import '../models/coupon.dart';
import '../models/restaurant.dart';
import '../sources/mock_catalog_data.dart';
import 'catalog_repository.dart';

/// Phase 1 catalog: the 8 launch partners of Birganj Pourashava, served
/// from a bundled dataset (instant on 2G, works fully offline). The
/// Phase 2 API returns the exact same JSON shape.
class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository();

  /// Launch coupons from the marketing plan (§7: first-100-users offers).
  static const List<Coupon> coupons = <Coupon>[
    Coupon(
      code: 'FIRSTFREE',
      description: 'প্রথম অর্ডারে ফ্রি ডেলিভারি',
      type: CouponType.freeDelivery,
      value: 0,
    ),
    Coupon(
      code: 'WELCOME40',
      description: '৳৪০ ফ্ল্যাট ছাড় (ন্যূনতম ৳১৫০ অর্ডার)',
      type: CouponType.flat,
      value: 40,
      minSubtotal: 150,
    ),
    Coupon(
      code: 'PETUK10',
      description: '১০% ছাড়, সর্বোচ্চ ৳৬০ (ন্যূনতম ৳২৫০ অর্ডার)',
      type: CouponType.percent,
      value: 10,
      minSubtotal: 250,
      maxDiscount: 60,
    ),
  ];

  @override
  Future<List<Restaurant>> fetchRestaurants() async {
    // Simulated fetch latency; the real source will be API + local cache.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return MockCatalogData.restaurants;
  }

  @override
  Future<Coupon> validateCoupon(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final String normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw const CouponException('কুপন কোড লিখুন।');
    }
    for (final Coupon coupon in coupons) {
      if (coupon.code == normalized) return coupon;
    }
    throw const CouponException('কুপন কোডটি সঠিক নয়।');
  }
}
