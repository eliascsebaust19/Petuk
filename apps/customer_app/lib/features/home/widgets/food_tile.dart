import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/food_image.dart';
import '../../../data/models/food_item.dart';

/// One menu row. Items with options (variants/spice/note) open the
/// detail sheet; simple items get a one-tap quick add.
class FoodTile extends StatelessWidget {
  const FoodTile({
    super.key,
    required this.food,
    required this.onTap,
    required this.onQuickAdd,
    this.enabled = true,
  });

  final FoodItem food;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  /// False when the restaurant is closed (browse-only).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      food.name,
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Text(
                          BnFormat.taka(food.price),
                          style: text.titleSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (food.variants.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${BnFormat.digits(food.variants.length)}টি সাইজ/সেট',
                              style: text.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FoodImage(
                    category: food.category,
                    imageUrl: food.imageUrl,
                    size: 84,
                  ),
                  const SizedBox(height: 8),
                  _buildAction(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (!food.isAvailable) {
      return _labelChip('স্টক নেই', AppColors.errorSoft, AppColors.error);
    }
    if (!enabled) {
      return _labelChip('বন্ধ', AppColors.background, AppColors.slate40);
    }
    return SizedBox(
      height: 32,
      width: 84,
      child: OutlinedButton(
        onPressed: food.hasOptions ? onTap : onQuickAdd,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(84, 32),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('যোগ করুন'),
      ),
    );
  }

  Widget _labelChip(String label, Color background, Color foreground) {
    return Container(
      width: 84,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
