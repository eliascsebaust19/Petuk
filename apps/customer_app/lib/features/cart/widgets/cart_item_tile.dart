import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/food_image.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../data/models/cart_item.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

/// A cart line with its options label and quantity stepper
/// (minus at quantity 1 removes the line).
class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FoodImage(
            category: item.food.category,
            imageUrl: item.food.imageUrl,
            size: 56,
            borderRadius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (item.optionsLabel.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    item.optionsLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  BnFormat.taka(item.lineTotal),
                  style: text.titleSmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuantityStepper(
            compact: true,
            quantity: item.quantity,
            onChanged: (int quantity) => context.read<CartBloc>().add(
                  CartItemQuantityChanged(
                    itemId: item.key,
                    quantity: quantity,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
