import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/food_image.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../data/models/food_item.dart';
import '../../../data/models/restaurant.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';

/// Opens the item customization sheet (SRS FR-C03: variations 1:1 / 1:2,
/// spice level, special notes like "পেঁয়াজ কম" or cake writing).
Future<void> showFoodDetailSheet(
  BuildContext context, {
  required FoodItem food,
  required Restaurant restaurant,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        FoodDetailSheet(food: food, restaurant: restaurant),
  );
}

class FoodDetailSheet extends StatefulWidget {
  const FoodDetailSheet({
    super.key,
    required this.food,
    required this.restaurant,
  });

  final FoodItem food;
  final Restaurant restaurant;

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  late FoodVariant? _variant = widget.food.variants.isNotEmpty
      ? widget.food.variants.first
      : null;
  late SpiceLevel? _spice =
      widget.food.spiceCustomizable ? SpiceLevel.medium : null;
  final TextEditingController _noteController = TextEditingController();
  int _quantity = 1;

  int get _unitPrice => widget.food.unitPrice(variant: _variant);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _add() {
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    context.read<CartBloc>().add(
          CartItemAdded(
            food: widget.food,
            restaurantName: widget.restaurant.name,
            variant: _variant,
            spice: _spice,
            note: _noteController.text.trim(),
            quantity: _quantity,
          ),
        );
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.food.name} কার্টে যোগ হয়েছে'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'কার্ট দেখুন',
          textColor: AppColors.accent,
          onPressed: () => navigator.pushNamed(AppRoutes.cart),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final FoodItem food = widget.food;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FoodImage(
                  category: food.category,
                  imageUrl: food.imageUrl,
                  size: 96,
                  borderRadius: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(food.name, style: text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        widget.restaurant.name,
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(food.description, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (food.variants.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              Text('সাইজ / সেট', style: text.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final FoodVariant variant in food.variants)
                    _OptionChip(
                      label: variant.priceDelta == 0
                          ? variant.label
                          : '${variant.label} (${variant.priceDelta > 0 ? '+' : '−'}${BnFormat.taka(variant.priceDelta.abs())})',
                      selected: _variant == variant,
                      onTap: () => setState(() => _variant = variant),
                    ),
                ],
              ),
            ],
            if (food.spiceCustomizable) ...<Widget>[
              const SizedBox(height: 20),
              Text('ঝালের মাত্রা', style: text.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final SpiceLevel level in SpiceLevel.values)
                    _OptionChip(
                      label: level.labelBn,
                      selected: _spice == level,
                      onTap: () => setState(() => _spice = level),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text('বিশেষ নির্দেশনা (ঐচ্ছিক)', style: text.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 120,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                counterText: '',
                hintText: food.noteHint ?? 'যেমন: পেঁয়াজ কম দেবেন…',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                QuantityStepper(
                  quantity: _quantity,
                  min: 1,
                  onChanged: (int value) =>
                      setState(() => _quantity = value),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label:
                        'যোগ করুন • ${BnFormat.taka(_unitPrice * _quantity)}',
                    onPressed: _add,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primaryDark : AppColors.slate60,
            ),
          ),
        ),
      ),
    );
  }
}
