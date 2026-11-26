import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_birganj/data/models/coupon.dart';
import 'package:foodie_birganj/data/models/food_item.dart';
import 'package:foodie_birganj/data/models/restaurant.dart';
import 'package:foodie_birganj/data/repositories/catalog_repository.dart';
import 'package:foodie_birganj/data/repositories/mock_catalog_repository.dart';
import 'package:foodie_birganj/data/sources/mock_catalog_data.dart';
import 'package:foodie_birganj/features/cart/bloc/cart_bloc.dart';
import 'package:foodie_birganj/features/cart/bloc/cart_event.dart';

/// Instant in-memory catalog for deterministic bloc tests.
class _FakeCatalogRepository implements CatalogRepository {
  @override
  Future<List<Restaurant>> fetchRestaurants() async =>
      MockCatalogData.restaurants;

  @override
  Future<Coupon> validateCoupon(String code) async {
    final String normalized = code.trim().toUpperCase();
    for (final Coupon coupon in MockCatalogRepository.coupons) {
      if (coupon.code == normalized) return coupon;
    }
    throw const CouponException('কুপন কোডটি সঠিক নয়।');
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late CartBloc bloc;

  final FoodItem kacchi = MockCatalogData.foodById('r1-f1')!; // ৳260
  final FoodItem borhani = MockCatalogData.foodById('r1-f5')!; // ৳40
  final FoodItem burger = MockCatalogData.foodById('r2-f1')!; // ৳120

  const String restaurant1 = 'বীরগঞ্জ বিরিয়ানি হাউজ';
  const String restaurant2 = 'ফুড কর্নার';

  setUp(() {
    bloc = CartBloc(catalogRepository: _FakeCatalogRepository());
  });

  tearDown(() => bloc.close());

  group('single-restaurant rule (QA-02)', () {
    test('first add adopts the restaurant and charges the flat fee',
        () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      await _settle();
      expect(bloc.state.restaurantId, 'r1');
      expect(bloc.state.items.length, 1);
      expect(bloc.state.subtotal, 40);
      expect(bloc.state.deliveryFee, 30);
      expect(bloc.state.grandTotal, 70);
    });

    test('same restaurant + identical options merges quantity', () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      await _settle();
      expect(bloc.state.items.length, 1);
      expect(bloc.state.totalQuantity, 2);
      expect(bloc.state.subtotal, 80);
    });

    test('different restaurant parks a pendingAddition (no mutation)',
        () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      bloc.add(
        const CartItemAdded(food: burger, restaurantName: restaurant2),
      );
      await _settle();
      expect(bloc.state.pendingAddition, isNotNull);
      expect(bloc.state.restaurantId, 'r1');
      expect(bloc.state.items.length, 1);
      expect(bloc.state.subtotal, 40);
    });

    test('confirm replaces the cart with the new restaurant', () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      bloc.add(
        const CartItemAdded(food: burger, restaurantName: restaurant2),
      );
      await _settle();
      bloc.add(const CartAdditionConfirmed());
      await _settle();
      expect(bloc.state.pendingAddition, isNull);
      expect(bloc.state.restaurantId, 'r2');
      expect(bloc.state.items.length, 1);
      expect(bloc.state.subtotal, 120);
      expect(bloc.state.grandTotal, 150);
    });

    test('cancel keeps the original cart untouched', () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      bloc.add(
        const CartItemAdded(food: burger, restaurantName: restaurant2),
      );
      await _settle();
      bloc.add(const CartAdditionCancelled());
      await _settle();
      expect(bloc.state.pendingAddition, isNull);
      expect(bloc.state.restaurantId, 'r1');
      expect(bloc.state.subtotal, 40);
    });

    test('removing the last item resets the restaurant', () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      await _settle();
      bloc.add(
        CartItemQuantityChanged(
          itemId: bloc.state.items.first.key,
          quantity: 0,
        ),
      );
      await _settle();
      expect(bloc.state.isEmpty, isTrue);
      expect(bloc.state.restaurantId, isNull);
      expect(bloc.state.deliveryFee, 0);
    });
  });

  group('options identity', () {
    test('different spice levels create separate lines', () async {
      bloc.add(
        const CartItemAdded(
          food: kacchi,
          restaurantName: restaurant1,
          spice: SpiceLevel.low,
        ),
      );
      bloc.add(
        const CartItemAdded(
          food: kacchi,
          restaurantName: restaurant1,
          spice: SpiceLevel.high,
        ),
      );
      await _settle();
      expect(bloc.state.items.length, 2);
      expect(bloc.state.subtotal, 520);
    });

    test('variant price delta is applied to the line', () async {
      bloc.add(
        CartItemAdded(
          food: kacchi,
          restaurantName: restaurant1,
          variant: kacchi.variants[1], // ১:২ সেট +৳140
        ),
      );
      await _settle();
      expect(bloc.state.subtotal, 400);
      expect(bloc.state.grandTotal, 430);
    });
  });

  group('coupons & bill math', () {
    test('WELCOME40 gives a flat ৳40 off', () async {
      bloc.add(
        const CartItemAdded(food: kacchi, restaurantName: restaurant1),
      );
      await _settle();
      bloc.add(const CartCouponApplyRequested('welcome40'));
      await _settle();
      expect(bloc.state.coupon?.code, 'WELCOME40');
      expect(bloc.state.discount, 40);
      expect(bloc.state.grandTotal, 260 + 30 - 40);
    });

    test('coupon below minimum is rejected with a notice', () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      await _settle();
      bloc.add(const CartCouponApplyRequested('WELCOME40'));
      await _settle();
      expect(bloc.state.coupon, isNull);
      expect(bloc.state.notice, isNotNull);
    });

    test('coupon is auto-removed when subtotal drops below minimum',
        () async {
      bloc.add(
        const CartItemAdded(
          food: borhani,
          restaurantName: restaurant1,
          quantity: 4,
        ),
      );
      await _settle();
      bloc.add(const CartCouponApplyRequested('WELCOME40'));
      await _settle();
      expect(bloc.state.coupon, isNotNull);
      bloc.add(
        CartItemQuantityChanged(
          itemId: bloc.state.items.first.key,
          quantity: 3, // ৳120 < ৳150 minimum
        ),
      );
      await _settle();
      expect(bloc.state.coupon, isNull);
      expect(bloc.state.discount, 0);
      expect(bloc.state.notice, isNotNull);
    });

    test('PETUK10 percent discount is capped at ৳60', () async {
      bloc.add(
        CartItemAdded(
          food: kacchi,
          restaurantName: restaurant1,
          variant: kacchi.variants[1],
          quantity: 2,
        ),
      );
      await _settle(); // subtotal ৳800 → 10% = 80 → capped 60
      bloc.add(const CartCouponApplyRequested('PETUK10'));
      await _settle();
      expect(bloc.state.discount, 60);
      expect(bloc.state.grandTotal, 800 + 30 - 60);
    });

    test('FIRSTFREE waives exactly the delivery fee', () async {
      bloc.add(
        const CartItemAdded(food: borhani, restaurantName: restaurant1),
      );
      await _settle();
      bloc.add(const CartCouponApplyRequested('FIRSTFREE'));
      await _settle();
      expect(bloc.state.discount, 30);
      expect(bloc.state.grandTotal, 40);
    });

    test('unknown code surfaces a notice, keeps the bill intact',
        () async {
      bloc.add(
        const CartItemAdded(food: kacchi, restaurantName: restaurant1),
      );
      await _settle();
      bloc.add(const CartCouponApplyRequested('NOPE'));
      await _settle();
      expect(bloc.state.coupon, isNull);
      expect(bloc.state.notice, isNotNull);
      expect(bloc.state.grandTotal, 290);
    });
  });
}
