import 'package:equatable/equatable.dart';

import 'cart_item.dart';
import 'delivery_address.dart';

/// The 4-step order pipeline (SRS FR-C06 / DFD Level 1).
enum OrderStatus { pending, preparing, onTheWay, delivered }

extension OrderStatusX on OrderStatus {
  String get labelBn => switch (this) {
        OrderStatus.pending => 'অর্ডার গৃহীত',
        OrderStatus.preparing => 'রান্না হচ্ছে',
        OrderStatus.onTheWay => 'পথে আছে',
        OrderStatus.delivered => 'ডেলিভারি সম্পন্ন',
      };

  String get hintBn => switch (this) {
        OrderStatus.pending =>
          'অপারেশন টিম অর্ডারটি রেস্তোরাঁকে জানাচ্ছে',
        OrderStatus.preparing => 'রেস্তোরাঁর কিচেনে আপনার খাবার তৈরি হচ্ছে',
        OrderStatus.onTheWay => 'রাইডার আপনার খাবার নিয়ে রওনা হয়েছে',
        OrderStatus.delivered => 'খাবার পৌঁছে গেছে — ধন্যবাদ!',
      };

  /// 0-based step used by the tracking progress bar.
  int get step => index;
}

/// Payment rails (SRS FR-C05). COD is the default (~80% of orders).
enum PaymentMethod { cod, bkash, nagad }

extension PaymentMethodX on PaymentMethod {
  String get labelBn => switch (this) {
        PaymentMethod.cod => 'ক্যাশ অন ডেলিভারি',
        PaymentMethod.bkash => 'বিকাশ',
        PaymentMethod.nagad => 'নগদ',
      };

  bool get isWallet => this != PaymentMethod.cod;
}

/// The assigned delivery partner (part-time college rider pool).
class Rider extends Equatable {
  const Rider({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.rating,
  });

  final String name;

  /// E.164 for the call button.
  final String phone;

  /// e.g. "বাইক • দিনাজপুর মেট্রো-ব ১১-২৩৪৫".
  final String vehicle;
  final double rating;

  String get initials => name.isEmpty ? '?' : name.substring(0, 1);

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      vehicle: (json['vehicle'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'vehicle': vehicle,
        'rating': rating,
      };

  @override
  List<Object?> get props => <Object?>[name, phone, vehicle, rating];
}

/// A placed order with its full bill snapshot and live status.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.address,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.placedAt,
    required this.statusTimes,
    required this.deliveryOtp,
    this.trxId,
    this.couponCode,
    this.rider,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final List<CartItem> items;
  final DeliveryAddress address;
  final PaymentMethod paymentMethod;

  /// bKash/Nagad transaction id when paid by wallet.
  final String? trxId;
  final String? couponCode;

  final int subtotal;
  final int deliveryFee;
  final int discount;
  final int total;

  final OrderStatus status;
  final DateTime placedAt;

  /// When each step was reached — rendered under the progress bar.
  final Map<OrderStatus, DateTime> statusTimes;

  /// 4-digit handover code the rider must collect (SRS Rider App spec).
  final String deliveryOtp;

  final Rider? rider;

  int get itemCount =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);

  Order copyWith({
    OrderStatus? status,
    Map<OrderStatus, DateTime>? statusTimes,
    Rider? rider,
  }) {
    return Order(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: items,
      address: address,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      status: status ?? this.status,
      placedAt: placedAt,
      statusTimes: statusTimes ?? this.statusTimes,
      deliveryOtp: deliveryOtp,
      trxId: trxId,
      couponCode: couponCode,
      rider: rider ?? this.rider,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> timesJson =
        (json['status_times'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<OrderStatus, DateTime> times = <OrderStatus, DateTime>{};
    for (final MapEntry<String, dynamic> entry in timesJson.entries) {
      for (final OrderStatus s in OrderStatus.values) {
        if (s.name == entry.key && entry.value is String) {
          times[s] = DateTime.parse(entry.value as String);
        }
      }
    }
    final Map<String, dynamic>? riderJson =
        json['rider'] as Map<String, dynamic>?;
    return Order(
      id: json['id'] as String,
      restaurantId: (json['restaurant_id'] as String?) ?? '',
      restaurantName: (json['restaurant_name'] as String?) ?? '',
      items: ((json['items'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      address: DeliveryAddress.fromJson(
        (json['address'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (PaymentMethod m) => m.name == json['payment_method'],
        orElse: () => PaymentMethod.cod,
      ),
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: OrderStatus.values.firstWhere(
        (OrderStatus s) => s.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      placedAt:
          DateTime.tryParse((json['placed_at'] as String?) ?? '') ??
              DateTime.now(),
      statusTimes: times,
      deliveryOtp: (json['delivery_otp'] as String?) ?? '',
      trxId: json['trx_id'] as String?,
      couponCode: json['coupon_code'] as String?,
      rider: riderJson == null ? null : Rider.fromJson(riderJson),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'items': items.map((CartItem i) => i.toJson()).toList(),
        'address': address.toJson(),
        'payment_method': paymentMethod.name,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount': discount,
        'total': total,
        'status': status.name,
        'placed_at': placedAt.toIso8601String(),
        'status_times': statusTimes.map(
          (OrderStatus s, DateTime t) =>
              MapEntry<String, String>(s.name, t.toIso8601String()),
        ),
        'delivery_otp': deliveryOtp,
        'trx_id': trxId,
        'coupon_code': couponCode,
        'rider': rider?.toJson(),
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        restaurantId,
        restaurantName,
        items,
        address,
        paymentMethod,
        trxId,
        couponCode,
        subtotal,
        deliveryFee,
        discount,
        total,
        status,
        placedAt,
        statusTimes,
        deliveryOtp,
        rider,
      ];
}
