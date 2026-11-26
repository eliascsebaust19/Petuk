import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/delivery_address.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../cart/bloc/cart_state.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class CheckoutPaymentMethodChanged extends CheckoutEvent {
  const CheckoutPaymentMethodChanged(this.method);

  final PaymentMethod method;

  @override
  List<Object?> get props => <Object?>[method];
}

/// Fired after the address form passes validation.
final class CheckoutPlaceOrderRequested extends CheckoutEvent {
  const CheckoutPlaceOrderRequested({
    required this.recipientName,
    required this.phone,
    required this.zone,
    required this.area,
    required this.landmark,
    this.note = '',
    this.trxId,
  });

  final String recipientName;

  /// E.164 phone.
  final String phone;
  final String zone;
  final String area;
  final String landmark;
  final String note;

  /// bKash/Nagad transaction id (required for wallet payments).
  final String? trxId;

  @override
  List<Object?> get props =>
      <Object?>[recipientName, phone, zone, area, landmark, note, trxId];
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum CheckoutStatus { editing, submitting, success, failure }

final class CheckoutState extends Equatable {
  const CheckoutState({
    this.paymentMethod = PaymentMethod.cod,
    this.status = CheckoutStatus.editing,
    this.orderId,
    this.error,
  });

  final PaymentMethod paymentMethod;
  final CheckoutStatus status;
  final String? orderId;
  final String? error;

  static const Object _unset = Object();

  CheckoutState copyWith({
    PaymentMethod? paymentMethod,
    CheckoutStatus? status,
    Object? orderId = _unset,
    Object? error = _unset,
  }) {
    return CheckoutState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      orderId:
          identical(orderId, _unset) ? this.orderId : orderId as String?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[paymentMethod, status, orderId, error];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// Places the order from the current cart snapshot, then clears the cart
/// and exposes the new order id for navigation to live tracking.
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required OrderRepository orderRepository,
    required CartBloc cartBloc,
  })  : _orderRepository = orderRepository,
        _cartBloc = cartBloc,
        super(const CheckoutState()) {
    on<CheckoutPaymentMethodChanged>(
      (CheckoutPaymentMethodChanged event, Emitter<CheckoutState> emit) =>
          emit(
        state.copyWith(paymentMethod: event.method, error: null),
      ),
    );
    on<CheckoutPlaceOrderRequested>(_onPlaceOrder);
  }

  final OrderRepository _orderRepository;
  final CartBloc _cartBloc;

  Future<void> _onPlaceOrder(
    CheckoutPlaceOrderRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    if (state.status == CheckoutStatus.submitting) return;

    final CartState cart = _cartBloc.state;
    if (cart.isEmpty || cart.restaurantId == null) {
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          error: 'কার্ট খালি — আগে খাবার যোগ করুন।',
        ),
      );
      return;
    }
    final String trxId = (event.trxId ?? '').trim();
    if (state.paymentMethod.isWallet && trxId.length < 6) {
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          error:
              '${state.paymentMethod.labelBn} পেমেন্টের সঠিক ট্রানজেকশন আইডি দিন।',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CheckoutStatus.submitting, error: null));
    try {
      final Order order = await _orderRepository.placeOrder(
        items: cart.items,
        restaurantId: cart.restaurantId!,
        restaurantName: cart.restaurantName ?? '',
        address: DeliveryAddress(
          recipientName: event.recipientName.trim(),
          phone: event.phone,
          zone: event.zone,
          area: event.area.trim(),
          landmark: event.landmark.trim(),
          note: event.note.trim(),
        ),
        paymentMethod: state.paymentMethod,
        trxId: state.paymentMethod.isWallet ? trxId : null,
        couponCode: cart.coupon?.code,
        deliveryFee: cart.deliveryFee,
        discount: cart.discount,
      );
      if (isClosed) return;
      _cartBloc.add(const CartClearRequested());
      emit(state.copyWith(status: CheckoutStatus.success, orderId: order.id));
    } on OrderException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.failure, error: error.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          error: 'অর্ডার করা যায়নি। আবার চেষ্টা করুন।',
        ),
      );
    }
  }
}
