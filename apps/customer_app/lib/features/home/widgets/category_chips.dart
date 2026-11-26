import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/food_category.dart';

/// Horizontal category chips: সব, বিরিয়ানি, বার্গার, পিৎজা, বার্থডে কেক, মিষ্টি.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// null = "সব".
  final FoodCategory? selected;
  final ValueChanged<FoodCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FoodCategory.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final FoodCategory? category =
              index == 0 ? null : FoodCategory.values[index - 1];
          final bool isSelected = selected == category;
          final String label = category == null
              ? 'সব'
              : '${category.emoji} ${category.labelBn}';
          return Material(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onSelected(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : AppColors.slate60,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
