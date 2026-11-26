import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class OrdersStarted extends OrdersEvent {
  const OrdersStarted();
}

final class _OrdersUpdated extends OrdersEvent {
  const _OrdersUpdated(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => <Object?>[orders];
}

final class _OrdersFailed extends OrdersEvent {
  const _OrdersFailed();
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum OrdersStatus { loading, ready, failure }

final class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.loading,
    this.orders = const <Order>[],
  });

  final OrdersStatus status;
  final List<Order> orders;

  /// Orders still moving through the pipeline.
  List<Order> get active => orders
      .where((Order o) => o.status != OrderStatus.delivered)
      .toList();

  List<Order> get past => orders
      .where((Order o) => o.status == OrderStatus.delivered)
      .toList();

  @override
  List<Object?> get props => <Object?>[status, orders];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// App-wide order list, kept live by the repository stream (every status
/// change re-emits).
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrdersState()) {
    on<OrdersStarted>(_onStarted);
    on<_OrdersUpdated>(
      (_OrdersUpdated event, Emitter<OrdersState> emit) =>
          emit(OrdersState(status: OrdersStatus.ready, orders: event.orders)),
    );
    on<_OrdersFailed>(
      (_OrdersFailed event, Emitter<OrdersState> emit) =>
          emit(const OrdersState(status: OrdersStatus.failure)),
    );
  }

  final OrderRepository _orderRepository;
  StreamSubscription<List<Order>>? _subscription;

  Future<void> _onStarted(
    OrdersStarted event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersState());
    await _subscription?.cancel();
    _subscription = _orderRepository.watchOrders().listen(
      (List<Order> orders) => add(_OrdersUpdated(orders)),
      onError: (Object _) => add(const _OrdersFailed()),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
