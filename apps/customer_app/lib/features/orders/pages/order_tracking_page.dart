import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bd_phone.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/bill_row.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../cart/widgets/bill_summary.dart';
import '../bloc/order_tracking_bloc.dart';
import '../widgets/delivery_otp_card.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_stepper.dart';
import '../widgets/rider_card.dart';

/// Live tracking (FR-C06): 4-step progress bar, rider contact card with
/// call button, handover OTP, address and bill — all updating in real
/// time from the order stream.
class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTrackingBloc>(
      create: (BuildContext context) => OrderTrackingBloc(
        orderRepository: context.read<OrderRepository>(),
        orderId: orderId,
      )..add(const TrackingStarted()),
      child: const _TrackingView(),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView();

  Future<void> _callSupport(BuildContext context) async {
    try {
      final bool launched = await launchUrl(
        Uri.parse('tel:${AppConstants.supportPhone}'),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কল করা যায়নি। আবার চেষ্টা করুন।')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কল করা যায়নি। আবার চেষ্টা করুন।')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('অর্ডার ট্র্যাকিং')),
      body: BlocBuilder<OrderTrackingBloc, TrackingState>(
        builder: (BuildContext context, TrackingState state) {
          if (state.status == TrackingStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TrackingStatus.missing ||
              state.order == null) {
            return EmptyState(
              emoji: '❓',
              title: 'অর্ডারটি পাওয়া যায়নি',
              message: 'অর্ডারটি খুঁজে পাওয়া যাচ্ছে না।',
              actionLabel: 'ফিরে যান',
              onAction: () => Navigator.of(context).pop(),
            );
          }
          final Order order = state.order!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'অর্ডার #${order.id}',
                          style: text.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          BnFormat.dateTime(order.placedAt),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: <Widget>[
                    OrderStatusStepper(
                      status: order.status,
                      statusTimes: order.statusTimes,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.slate60,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.status.hintBn,
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RiderCard(rider: order.rider, status: order.status),
              const SizedBox(height: 12),
              DeliveryOtpCard(
                otp: order.deliveryOtp,
                delivered: order.status == OrderStatus.delivered,
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'ডেলিভারি ঠিকানা',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.address.recipientName,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      BdPhone.pretty(order.address.phone),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.address.oneLine,
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (order.address.note.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        'নোট: ${order.address.note}',
                        style: text.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: order.restaurantName,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final CartItem item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${BnFormat.digits(item.quantity)}×',
                              style: text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.food.name,
                                    style: text.bodyMedium,
                                  ),
                                  if (item.optionsLabel.isNotEmpty)
                                    Text(
                                      item.optionsLabel,
                                      style: text.labelSmall,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              BnFormat.taka(item.lineTotal),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 20),
                    BillSummary(
                      subtotal: order.subtotal,
                      deliveryFee: order.deliveryFee,
                      discount: order.discount,
                      grandTotal: order.total,
                      couponCode: order.couponCode,
                    ),
                    const SizedBox(height: 8),
                    BillRow(
                      'পেমেন্ট',
                      order.paymentMethod.labelBn +
                          (order.trxId != null
                              ? ' • TrxID: ${order.trxId}'
                              : ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _callSupport(context),
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('সমস্যা? আমাদের কল করুন'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
