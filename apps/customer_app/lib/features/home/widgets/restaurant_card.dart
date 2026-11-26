import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/food_image.dart';
import '../../../data/models/restaurant.dart';

/// Discovery card: photo/visual, open-busy status, rating, ETA and
/// distance with subtle press scale and low-contrast soft shadow.
class RestaurantCard extends StatefulWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.distanceOverrideKm,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;
  final double? distanceOverrideKm;

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Restaurant restaurant = widget.restaurant;
    final double effectiveKm =
        widget.distanceOverrideKm ?? restaurant.distanceKm;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onHighlightChanged: (bool v) => setState(() => _pressed = v),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FoodImage(
                      category: restaurant.primaryCategory,
                      imageUrl: restaurant.imageUrl,
                      size: 88,
                      borderRadius: 14,
                    ),
                    const SizedBox(width: 14),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.accentSoft,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${BnFormat.digits(restaurant.rating.toStringAsFixed(1))} (${BnFormat.digits(restaurant.ratingCount)})',
                                      style: text.labelMedium?.copyWith(
                                        color: AppColors.accentDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${BnFormat.digits(restaurant.etaMinutes)} মিনিট',
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.slate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${BnFormat.digits(effectiveKm.toStringAsFixed(1))} কিমি',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.flag_outlined,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  restaurant.landmark,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
