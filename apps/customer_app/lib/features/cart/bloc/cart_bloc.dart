import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/bn_format.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/catalog_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// Core cart logic (SRS FR-C03/04/05, QA-02).
///
/// Invariants:
/// 1. SINGLE RESTAURANT — items from a second restaurant are parked in
///    `pendingAddition`; the UI shows a confirm dialog and dispatches
///    [CartAdditionConfirmed] (replace) or [CartAdditionCancelled] (keep).
/// 2. MERGE IDENTITY — same food + variant + spice + note merges quantity.
/// 3. DERIVED BILL — subtotal + flat ৳30 fee − coupon discount = grand
///    total; a coupon that stops meeting its minimum is auto-removed
///    with a notice.
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartAdditionConfirmed>(_onAdditionConfirmed);
    on<CartAdditionCancelled>(_onAdditionCancelled);
    on<CartItemQuantityChanged>(_onQuantityChanged);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartClearRequested>(_onClearRequested);
    on<CartCouponApplyRequested>(_onCouponApplyRequested);
    on<CartCouponRemoved>(_onCouponRemoved);
    on<CartNoticeCleared>(_onNoticeCleared);
  }

  final CatalogRepository _catalogRepository;

  // -------------------------------------------------------------------
  // Adding items — the single-restaurant rule.
  // -------------------------------------------------------------------

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    if (!event.food.isAvailable) {
      emit(state.copyWith(notice: 'এই আইটেমটি এখন স্টকে নেই।'));
      return;
    }
    final CartItem incoming = CartItem(
      food: event.food,
      variant: event.variant,
      spice: event.spice,
      note: event.note,
      quantity: event.quantity,
    );

    // Empty cart → adopt the item's restaurant.
    if (state.isEmpty) {
      emit(
        state.copyWith(
          restaurantId: incoming.restaurantId,
          restaurantName: event.restaurantName,
          items: <CartItem>[incoming],
          pendingAddition: null,
        ),
      );
      return;
    }

    // Same restaurant → merge or append.
    if (state.restaurantId == incoming.restaurantId) {
      emit(state.copyWith(items: _merge(state.items, incoming)));
      return;
    }

    // Different restaurant → park the request for the dialog (QA-02).
    emit(
      state.copyWith(
        pendingAddition: CartAddition(
          food: event.food,
          restaurantName: event.restaurantName,
          variant: event.variant,
          spice: event.spice,
          note: event.note,
          quantity: event.quantity,
        ),
      ),
    );
  }

  void _onAdditionConfirmed(
    CartAdditionConfirmed event,
    Emitter<CartState> emit,
  ) {
    final CartAddition? pending = state.pendingAddition;
    if (pending == null) return;
    final CartItem item = pending.toCartItem();
    final CartState next = state.copyWith(
      restaurantId: item.restaurantId,
      restaurantName: pending.restaurantName,
      items: <CartItem>[item],
      pendingAddition: null,
      notice: 'নতুন রেস্তোরাঁ দিয়ে নতুন কার্ট শুরু হয়েছে।',
    );
    emit(_settled(next));
  }

  void _onAdditionCancelled(
    CartAdditionCancelled event,
    Emitter<CartState> emit,
  ) {
    if (state.pendingAddition == null) return;
    emit(state.copyWith(pendingAddition: null));
  }

  // -------------------------------------------------------------------
  // Quantities & removal.
  // -------------------------------------------------------------------

  void _onQuantityChanged(
    CartItemQuantityChanged event,
    Emitter<CartState> emit,
  ) {
    final int index =
        state.items.indexWhere((CartItem item) => item.key == event.itemId);
    if (index == -1) return;
    final int quantity =
        math.min(math.max(event.quantity, 0), AppConstants.maxItemQuantity);
    final List<CartItem> items = List<CartItem>.of(state.items);
    if (quantity == 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    emit(_settled(state.copyWith(items: items)));
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final List<CartItem> items = List<CartItem>.of(state.items)
      ..removeWhere((CartItem item) => item.key == event.itemId);
    emit(_settled(state.copyWith(items: items)));
  }

  void _onClearRequested(CartClearRequested event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  // -------------------------------------------------------------------
  // Coupons.
  // -------------------------------------------------------------------

  Future<void> _onCouponApplyRequested(
    CartCouponApplyRequested event,
    Emitter<CartState> emit,
  ) async {
    if (state.couponBusy) return;
    if (state.isEmpty) {
      emit(
        state.copyWith(
          notice: 'আগে কার্টে খাবার যোগ করুন, তারপর কুপন দিন।',
        ),
      );
      return;
    }
    emit(state.copyWith(couponBusy: true));
    try {
      final Coupon coupon =
          await _catalogRepository.validateCoupon(event.code);
      if (isClosed) return;
      if (!coupon.appliesTo(state.subtotal)) {
        emit(
          state.copyWith(
            couponBusy: false,
            notice:
                '"${coupon.code}" ব্যবহার করতে ন্যূনতম ${BnFormat.taka(coupon.minSubtotal)} অর্ডার লাগবে।',
          ),
        );
        return;
      }
      final int saved = coupon.discountFor(
        subtotal: state.subtotal,
        deliveryFee: state.deliveryFee,
      );
      emit(
        state.copyWith(
          coupon: coupon,
          couponBusy: false,
          notice: 'কুপন যুক্ত হয়েছে — ${BnFormat.taka(saved)} ছাড়! 🎉',
        ),
      );
    } on CouponException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(couponBusy: false, notice: error.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          couponBusy: false,
          notice: 'কুপন যাচাই করা যায়নি। আবার চেষ্টা করুন।',
        ),
      );
    }
  }

  void _onCouponRemoved(CartCouponRemoved event, Emitter<CartState> emit) {
    if (state.coupon == null) return;
    emit(state.copyWith(coupon: null, notice: 'কুপন সরানো হয়েছে।'));
  }

  void _onNoticeCleared(CartNoticeCleared event, Emitter<CartState> emit) {
    if (state.notice == null) return;
    emit(state.copyWith(notice: null));
  }

  // -------------------------------------------------------------------
  // Helpers.
  // -------------------------------------------------------------------

  /// Merge by identity key, capping quantity at the business maximum.
  List<CartItem> _merge(List<CartItem> items, CartItem incoming) {
    final List<CartItem> result = List<CartItem>.of(items);
    final int index =
        result.indexWhere((CartItem item) => item.key == incoming.key);
    if (index == -1) {
      result.add(incoming);
    } else {
      final int quantity = math.min(
        result[index].quantity + incoming.quantity,
        AppConstants.maxItemQuantity,
      );
      result[index] = result[index].copyWith(quantity: quantity);
    }
    return result;
  }

  /// Post-mutation invariants: empty cart resets everything; a coupon
  /// that no longer meets its minimum subtotal is removed with a notice.
  CartState _settled(CartState next) {
    if (next.items.isEmpty) {
      return next.copyWith(
        restaurantId: null,
        restaurantName: null,
        coupon: null,
        items: const <CartItem>[],
      );
    }
    final Coupon? coupon = next.coupon;
    if (coupon != null && !coupon.appliesTo(next.subtotal)) {
      return next.copyWith(
        coupon: null,
        notice:
            'ন্যূনতম ${BnFormat.taka(coupon.minSubtotal)} অর্ডার না থাকায় "${coupon.code}" কুপনটি সরানো হয়েছে।',
      );
    }
    return next;
  }
}
