import 'dart:async';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../models/cart_item.dart';
import '../models/delivery_address.dart';
import '../models/food_item.dart';
import '../models/order.dart';
import '../sources/mock_catalog_data.dart';
import 'order_repository.dart';

/// Phase 1 order pipeline.
///
/// Mirrors the real operation: the order is accepted by the ops team
/// (PENDING), forwarded to the kitchen (PREPARING), picked up by a rider
/// (ON_THE_WAY, rider assigned) and handed over against the 4-digit OTP
/// (DELIVERED). Status transitions are driven by timers here; the Phase 2
/// backend will drive the exact same streams via FCM + realtime rows.
class MockOrderRepository implements OrderRepository {
  MockOrderRepository({Random? random})
      : _random = random ?? Random.secure() {
    _seedHistory();
  }

  final Random _random;
  final Map<String, Order> _orders = <String, Order>{};
  final Map<String, List<Timer>> _timers = <String, List<Timer>>{};
  final StreamController<List<Order>> _controller =
      StreamController<List<Order>>.broadcast();

  int _nextId = 100235;

  static const List<Rider> _riderPool = <Rider>[
    Rider(
      name: 'রাকিব হাসান',
      phone: '+8801712345678',
      vehicle: 'বাইক • দিনাজপুর মেট্রো-ব ১১-২৩৪৫',
      rating: 4.8,
    ),
    Rider(
      name: 'সাদমান সাকিব',
      phone: '+8801812345678',
      vehicle: 'সাইকেল • বীরগঞ্জ কলেজ রাইডার',
      rating: 4.7,
    ),
    Rider(
      name: 'মেহেদী হাসান',
      phone: '+8801912345678',
      vehicle: 'বাইক • দিনাজপুর মেট্রো-ল ১৪-০৮৭৬',
      rating: 4.9,
    ),
  ];

  /// One completed order from yesterday so the orders tab demonstrates
  /// history + reorder context on first launch.
  void _seedHistory() {
    final DateTime placed =
        DateTime.now().subtract(const Duration(days: 1, hours: 2));
    final FoodItem kacchi = MockCatalogData.foodById('r1-f1')!;
    final FoodItem borhani = MockCatalogData.foodById('r1-f5')!;
    final List<CartItem> items = <CartItem>[
      CartItem(food: kacchi, spice: SpiceLevel.medium),
      CartItem(food: borhani, quantity: 2),
    ];
    const int subtotal = 260 + 40 * 2;
    const int fee = AppConstants.deliveryFee;
    const int discount = 40;
    final Order order = Order(
      id: 'PB100234',
      restaurantId: 'r1',
      restaurantName: 'বীরগঞ্জ বিরিয়ানি হাউজ',
      items: items,
      address: const DeliveryAddress(
        recipientName: 'ডেমো গ্রাহক',
        phone: '+8801712345678',
        zone: AppConstants.defaultZone,
        area: 'কলেজ রোড',
        landmark: 'সোনালী ব্যাংকের পেছনে',
      ),
      paymentMethod: PaymentMethod.cod,
      subtotal: subtotal,
      deliveryFee: fee,
      discount: discount,
      total: subtotal + fee - discount,
      status: OrderStatus.delivered,
      placedAt: placed,
      statusTimes: <OrderStatus, DateTime>{
        OrderStatus.pending: placed,
        OrderStatus.preparing: placed.add(const Duration(minutes: 10)),
        OrderStatus.onTheWay: placed.add(const Duration(minutes: 26)),
        OrderStatus.delivered: placed.add(const Duration(minutes: 49)),
      },
      deliveryOtp: '4821',
      couponCode: 'WELCOME40',
      rider: _riderPool.first,
    );
    _orders[order.id] = order;
  }

  @override
  Future<Order> placeOrder({
    required List<CartItem> items,
    required String restaurantId,
    required String restaurantName,
    required DeliveryAddress address,
    required PaymentMethod paymentMethod,
    String? trxId,
    String? couponCode,
    required int deliveryFee,
    required int discount,
  }) async {
    // Simulated round-trip to the central backend.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (items.isEmpty) {
      throw const OrderException('কার্ট খালি — অর্ডার করা যায়নি।');
    }
    final int subtotal =
        items.fold(0, (int sum, CartItem item) => sum + item.lineTotal);
    final DateTime now = DateTime.now();
    final String id = 'PB${_nextId++}';
    final String otp = List<String>.generate(
      4,
      (_) => _random.nextInt(10).toString(),
    ).join();
    final Order order = Order(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: List<CartItem>.unmodifiable(items),
      address: address,
      paymentMethod: paymentMethod,
      trxId: trxId,
      couponCode: couponCode,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: subtotal + deliveryFee - discount,
      status: OrderStatus.pending,
      placedAt: now,
      statusTimes: <OrderStatus, DateTime>{OrderStatus.pending: now},
      deliveryOtp: otp,
    );
    _orders[id] = order;
    _notify();
    _schedulePipeline(id);
    return order;
  }

  void _schedulePipeline(String id) {
    _timers[id] = <Timer>[
      Timer(
        const Duration(seconds: AppConstants.mockPreparingAfterSeconds),
        () => _advance(id, OrderStatus.preparing),
      ),
      Timer(
        const Duration(seconds: AppConstants.mockOnTheWayAfterSeconds),
        () => _advance(id, OrderStatus.onTheWay, assignRider: true),
      ),
      Timer(
        const Duration(seconds: AppConstants.mockDeliveredAfterSeconds),
        () => _advance(id, OrderStatus.delivered),
      ),
    ];
  }

  void _advance(String id, OrderStatus status, {bool assignRider = false}) {
    final Order? current = _orders[id];
    if (current == null || current.status.index >= status.index) return;
    final Map<OrderStatus, DateTime> times =
        Map<OrderStatus, DateTime>.of(current.statusTimes)
          ..[status] = DateTime.now();
    _orders[id] = current.copyWith(
      status: status,
      statusTimes: times,
      rider: assignRider
          ? _riderPool[_random.nextInt(_riderPool.length)]
          : null,
    );
    _notify();
  }

  void _notify() {
    if (!_controller.isClosed) _controller.add(_sorted());
  }

  List<Order> _sorted() {
    final List<Order> list = _orders.values.toList();
    list.sort((Order a, Order b) => b.placedAt.compareTo(a.placedAt));
    return list;
  }

  @override
  Stream<List<Order>> watchOrders() async* {
    yield _sorted();
    yield* _controller.stream;
  }

  @override
  Stream<Order?> watchOrder(String id) async* {
    yield _orders[id];
    yield* _controller.stream.map((List<Order> _) => _orders[id]).distinct();
  }

  @override
  void dispose() {
    for (final List<Timer> timers in _timers.values) {
      for (final Timer timer in timers) {
        timer.cancel();
      }
    }
    _timers.clear();
    _controller.close();
  }
}
