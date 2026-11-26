import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

/// Coupon input → applied chip. Validation feedback arrives through the
/// cart's one-shot `notice` (global snackbar).
class CouponField extends StatefulWidget {
  const CouponField({super.key});

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BlocBuilder<CartBloc, CartState>(
      builder: (BuildContext context, CartState state) {
        final coupon = state.coupon;
        if (coupon != null) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        coupon.code,
                        style: text.titleSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        coupon.description,
                        style: text.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'কুপন সরান',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context
                      .read<CartBloc>()
                      .add(const CartCouponRemoved()),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.slate60,
                  ),
                ),
              ],
            ),
          );
        }
        return Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (String code) => context
                    .read<CartBloc>()
                    .add(CartCouponApplyRequested(code)),
                decoration: const InputDecoration(
                  hintText: 'কুপন কোড (যেমন: WELCOME40)',
                  prefixIcon: Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.slate40,
                    size: 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: state.couponBusy
                    ? null
                    : () => context.read<CartBloc>().add(
                          CartCouponApplyRequested(_controller.text),
                        ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(88, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: state.couponBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text('প্রয়োগ'),
              ),
            ),
          ],
        );
      },
    );
  }
}
