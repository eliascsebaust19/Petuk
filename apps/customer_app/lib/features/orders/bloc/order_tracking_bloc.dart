import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class TrackingStarted extends TrackingEvent {
  const TrackingStarted();
}

final class _TrackingUpdated extends TrackingEvent {
  const _TrackingUpdated(this.order);

  final Order? order;

  @override
  List<Object?> get props => <Object?>[order];
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum TrackingStatus { loading, ready, missing }

final class TrackingState extends Equatable {
  const TrackingState({
    this.status = TrackingStatus.loading,
    this.order,
  });

  final TrackingStatus status;
  final Order? order;

  @override
  List<Object?> get props => <Object?>[status, order];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// Live tracking of one order — one bloc per tracking screen, fed by the
/// repository's per-order stream (FR-C06).
class OrderTrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  OrderTrackingBloc({
    required OrderRepository orderRepository,
    required this.orderId,
  })  : _orderRepository = orderRepository,
        super(const TrackingState()) {
    on<TrackingStarted>(_onStarted);
    on<_TrackingUpdated>(
      (_TrackingUpdated event, Emitter<TrackingState> emit) {
        final Order? order = event.order;
        if (order == null) {
          emit(const TrackingState(status: TrackingStatus.missing));
        } else {
          emit(TrackingState(status: TrackingStatus.ready, order: order));
        }
      },
    );
  }

  final OrderRepository _orderRepository;
  final String orderId;

  StreamSubscription<Order?>? _subscription;

  Future<void> _onStarted(
    TrackingStarted event,
    Emitter<TrackingState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _orderRepository.watchOrder(orderId).listen(
      (Order? order) => add(_TrackingUpdated(order)),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
