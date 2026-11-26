import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/food_image.dart';
import '../../../data/models/restaurant.dart';

/// Discovery card: photo/visual, open-busy status, rating, ETA and
/// distance (SRS FR-C02).
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FoodImage(
                  category: restaurant.primaryCategory,
                  imageUrl: restaurant.imageUrl,
                  size: 88,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RestaurantStatusChip(status: restaurant.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.cuisine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${BnFormat.digits(restaurant.rating.toStringAsFixed(1))} (${BnFormat.digits(restaurant.ratingCount)})',
                            style: text.labelMedium,
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.slate40,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${BnFormat.digits(restaurant.etaMinutes)} মিনিট',
                            style: text.bodySmall,
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: AppColors.slate40,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${BnFormat.digits(restaurant.distanceKm.toStringAsFixed(1))} কিমি',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.landmark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestaurantStatusChip extends StatelessWidget {
  const RestaurantStatusChip({super.key, required this.status});

  final RestaurantStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (status) {
      RestaurantStatus.open => (AppColors.successSoft, AppColors.success),
      RestaurantStatus.busy => (AppColors.accentSoft, AppColors.accentDark),
      RestaurantStatus.closed => (AppColors.errorSoft, AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.labelBn,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
