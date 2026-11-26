import '../models/cart_item.dart';
import '../models/delivery_address.dart';
import '../models/order.dart';

/// Order placement + live tracking (SRS FR-C05/06).
abstract interface class OrderRepository {
  /// Places an order from the cart snapshot and returns the created order
  /// (status `pending`, 4-digit handover OTP generated).
  ///
  /// Throws [OrderException] with a Bangla message on failure.
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
  });

  /// All orders, newest first. Emits again on every status change.
  Stream<List<Order>> watchOrders();

  /// A single order by id; emits on every status change (live tracking).
  Stream<Order?> watchOrder(String id);

  /// Releases timers/streams.
  void dispose();
}

/// Thrown when an order cannot be placed.
class OrderException implements Exception {
  const OrderException(this.message);

  final String message;

  @override
  String toString() => 'OrderException: $message';
}
