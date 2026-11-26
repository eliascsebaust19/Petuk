import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/coupon.dart';
import '../../../data/models/food_item.dart';

/// An add-to-cart request from a DIFFERENT restaurant, parked until the
/// user answers the "clear previous cart?" dialog (SRS QA-02).
final class CartAddition extends Equatable {
  const CartAddition({
    required this.food,
    required this.restaurantName,
    this.variant,
    this.spice,
    this.note = '',
    this.quantity = 1,
  });

  final FoodItem food;
  final String restaurantName;
  final FoodVariant? variant;
  final SpiceLevel? spice;
  final String note;
  final int quantity;

  CartItem toCartItem() => CartItem(
        food: food,
        variant: variant,
        spice: spice,
        note: note,
        quantity: quantity,
      );

  @override
  List<Object?> get props =>
      <Object?>[food, restaurantName, variant, spice, note, quantity];
}

/// Immutable cart snapshot. All money math is derived (never stored), so
/// subtotal → fee → discount → grand total can never drift apart.
final class CartState extends Equatable {
  const CartState({
    this.restaurantId,
    this.restaurantName,
    this.items = const <CartItem>[],
    this.coupon,
    this.pendingAddition,
    this.notice,
    this.couponBusy = false,
  });

  /// The single restaurant this cart belongs to (null when empty).
  final String? restaurantId;
  final String? restaurantName;
  final List<CartItem> items;
  final Coupon? coupon;

  /// Non-null while the restaurant-switch dialog must be shown.
  final CartAddition? pendingAddition;

  /// One-shot message for the global snackbar (coupon feedback etc.).
  final String? notice;

  /// True while a coupon code is being validated.
  final bool couponBusy;

  bool get isEmpty => items.isEmpty;

  bool get hasPendingConflict => pendingAddition != null;

  int get totalQuantity =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);

  int get subtotal =>
      items.fold(0, (int sum, CartItem item) => sum + item.lineTotal);

  /// Flat ৳30 delivery fee on any non-empty cart (business rule).
  int get deliveryFee => isEmpty ? 0 : AppConstants.deliveryFee;

  int get discount =>
      coupon?.discountFor(subtotal: subtotal, deliveryFee: deliveryFee) ?? 0;

  int get grandTotal => subtotal + deliveryFee - discount;

  /// Sentinel so `copyWith` can explicitly null-out nullable fields.
  static const Object _unset = Object();

  CartState copyWith({
    Object? restaurantId = _unset,
    Object? restaurantName = _unset,
    List<CartItem>? items,
    Object? coupon = _unset,
    Object? pendingAddition = _unset,
    Object? notice = _unset,
    bool? couponBusy,
  }) {
    return CartState(
      restaurantId: identical(restaurantId, _unset)
          ? this.restaurantId
          : restaurantId as String?,
      restaurantName: identical(restaurantName, _unset)
          ? this.restaurantName
          : restaurantName as String?,
      items: items ?? this.items,
      coupon: identical(coupon, _unset) ? this.coupon : coupon as Coupon?,
      pendingAddition: identical(pendingAddition, _unset)
          ? this.pendingAddition
          : pendingAddition as CartAddition?,
      notice: identical(notice, _unset) ? this.notice : notice as String?,
      couponBusy: couponBusy ?? this.couponBusy,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        restaurantId,
        restaurantName,
        items,
        coupon,
        pendingAddition,
        notice,
        couponBusy,
      ];
}
