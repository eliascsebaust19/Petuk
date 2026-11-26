import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../home/bloc/shell_cubit.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/bill_summary.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/coupon_field.dart';

/// The cart: single-restaurant header, line items, coupon, transparent
/// bill and the checkout CTA. Works both as a shell tab and a pushed
/// route (from menu pages / snackbars).
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final CartBloc cartBloc = context.read<CartBloc>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('কার্ট খালি করবেন?'),
        content: const Text('কার্টের সব খাবার ও কুপন মুছে যাবে।'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('না'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('খালি করুন'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cartBloc.add(const CartClearRequested());
    }
  }

  void _browseFood(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    final ShellCubit? shell = context.read<ShellCubit?>();
    if (shell != null) {
      shell.goHome();
    } else if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('আপনার কার্ট'),
        actions: <Widget>[
          BlocBuilder<CartBloc, CartState>(
            buildWhen: (CartState p, CartState c) => p.isEmpty != c.isEmpty,
            builder: (BuildContext context, CartState state) {
              if (state.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmClear(context),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                label: const Text(
                  'খালি করুন',
                  style: TextStyle(color: AppColors.error),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (BuildContext context, CartState state) {
          if (state.isEmpty) {
            return EmptyState(
              emoji: '🛒',
              title: 'কার্ট খালি',
              message:
                  'পছন্দের রেস্তোরাঁ থেকে খাবার যোগ করুন — এক অর্ডারে একটি রেস্তোরাঁর খাবার থাকবে।',
              actionLabel: 'খাবার দেখুন',
              onAction: () => _browseFood(context),
            );
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primaryDark,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.restaurantName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          Text(
                            '${BnFormat.digits(state.totalQuantity)} আইটেম',
                            style: text.labelMedium?.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (int i = 0; i < state.items.length; i++) ...<Widget>[
                      CartItemTile(item: state.items[i]),
                      if (i < state.items.length - 1) const Divider(),
                    ],
                    const SizedBox(height: 16),
                    const CouponField(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: BillSummary(
                        subtotal: state.subtotal,
                        deliveryFee: state.deliveryFee,
                        discount: state.discount,
                        grandTotal: state.grandTotal,
                        couponCode: state.coupon?.code,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'ডেলিভারি চার্জ ফ্ল্যাট ${BnFormat.taka(AppConstants.deliveryFee)} — কোনো লুকানো ফি নেই।',
                        style: text.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('মোট', style: text.labelSmall),
                          Text(
                            BnFormat.taka(state.grandTotal),
                            style: text.titleLarge?.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: 'চেকআউট করুন',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.checkout),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
