import 'package:equatable/equatable.dart';

import '../../../data/models/food_item.dart';

/// All user intents that can mutate the cart.
sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Add a food item. If it belongs to a different restaurant than the
/// current cart, the bloc emits `pendingAddition` instead of mutating —
/// the UI must resolve it with [CartAdditionConfirmed]/[CartAdditionCancelled].
final class CartItemAdded extends CartEvent {
  const CartItemAdded({
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

  @override
  List<Object?> get props =>
      <Object?>[food, restaurantName, variant, spice, note, quantity];
}

/// "কার্ট খালি করে যোগ করুন" — replace the cart with the pending item.
final class CartAdditionConfirmed extends CartEvent {
  const CartAdditionConfirmed();
}

/// "বাতিল" — keep the existing cart, drop the pending item.
final class CartAdditionCancelled extends CartEvent {
  const CartAdditionCancelled();
}

/// Set the absolute quantity of a line (0 removes it).
final class CartItemQuantityChanged extends CartEvent {
  const CartItemQuantityChanged({required this.itemId, required this.quantity});

  /// [CartItem.key] of the target line.
  final String itemId;
  final int quantity;

  @override
  List<Object?> get props => <Object?>[itemId, quantity];
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => <Object?>[itemId];
}

/// Empty the cart completely (also used after a successful checkout).
final class CartClearRequested extends CartEvent {
  const CartClearRequested();
}

final class CartCouponApplyRequested extends CartEvent {
  const CartCouponApplyRequested(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

final class CartCouponRemoved extends CartEvent {
  const CartCouponRemoved();
}

/// Acknowledges the one-shot snackbar notice so it never replays.
final class CartNoticeCleared extends CartEvent {
  const CartNoticeCleared();
}
