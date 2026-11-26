import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/food_image.dart';
import '../../../data/models/food_category.dart';
import '../../../data/models/food_item.dart';
import '../../../data/models/restaurant.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../cart/bloc/cart_state.dart';
import '../widgets/food_tile.dart';
import '../widgets/food_detail_sheet.dart';
import '../widgets/restaurant_card.dart';

/// Restaurant cover + info + menu grouped by category, with a sticky
/// "view cart" bar while this restaurant owns the cart.
class RestaurantMenuPage extends StatelessWidget {
  const RestaurantMenuPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  List<FoodCategory> get _categories => FoodCategory.values
      .where((FoodCategory c) => restaurant.categories.contains(c))
      .toList();

  void _quickAdd(BuildContext context, FoodItem food) {
    context.read<CartBloc>().add(
          CartItemAdded(food: food, restaurantName: restaurant.name),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} কার্টে যোগ হয়েছে'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'কার্ট দেখুন',
          textColor: AppColors.accent,
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.cart),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            actions: <Widget>[
              BlocBuilder<CartBloc, CartState>(
                buildWhen: (CartState p, CartState c) =>
                    p.totalQuantity != c.totalQuantity,
                builder: (BuildContext context, CartState cart) {
                  return IconButton(
                    tooltip: 'কার্ট',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.cart),
                    icon: cart.totalQuantity == 0
                        ? const Icon(Icons.shopping_cart_outlined)
                        : Badge(
                            backgroundColor: AppColors.accent,
                            label: Text(
                              BnFormat.digits(cart.totalQuantity),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                end: 16,
                bottom: 14,
              ),
              title: Text(
                restaurant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (restaurant.imageUrl != null &&
                      restaurant.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget:
                          (BuildContext context, String _, Object __) =>
                              _coverFallback(),
                    )
                  else
                    _coverFallback(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[
                          Color(0xB3000000),
                          Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _RestaurantInfo(restaurant: restaurant)),
          if (!restaurant.isOrderable)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'এই রেস্তোরাঁটি এখন বন্ধ — মেনু দেখা যাবে, তবে অর্ডার করা যাবে না।',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (final FoodCategory category in _categories) ...<Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  '${category.emoji} ${category.labelBn}',
                  style: text.titleMedium,
                ),
              ),
            ),
            SliverList.separated(
              itemCount: restaurant.menu
                  .where((FoodItem f) => f.category == category)
                  .length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (BuildContext context, int index) {
                final FoodItem food = restaurant.menu
                    .where((FoodItem f) => f.category == category)
                    .elementAt(index);
                return FoodTile(
                  food: food,
                  enabled: restaurant.isOrderable,
                  onTap: () => showFoodDetailSheet(
                    context,
                    food: food,
                    restaurant: restaurant,
                  ),
                  onQuickAdd: () => _quickAdd(context, food),
                );
              },
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (BuildContext context, CartState cart) {
          if (cart.isEmpty || cart.restaurantId != restaurant.id) {
            return const SizedBox.shrink();
          }
          return Material(
            color: AppColors.primary,
            child: InkWell(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.cart),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '${BnFormat.digits(cart.totalQuantity)} আইটেম • ${BnFormat.taka(cart.subtotal)}',
                        style: text.titleSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const Spacer(),
                      const Text(
                        'কার্ট দেখুন',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _coverFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: categoryGradient(restaurant.primaryCategory),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          restaurant.primaryCategory.emoji,
          style: const TextStyle(fontSize: 72),
        ),
      ),
    );
  }
}

class _RestaurantInfo extends StatelessWidget {
  const _RestaurantInfo({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(restaurant.name, style: text.titleLarge),
              ),
              RestaurantStatusChip(status: restaurant.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(restaurant.cuisine, style: text.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 2),
              Text(
                '${BnFormat.digits(restaurant.rating.toStringAsFixed(1))} (${BnFormat.digits(restaurant.ratingCount)} রিভিউ)',
                style: text.labelMedium,
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.slate40,
              ),
              const SizedBox(width: 3),
              Text(
                '${BnFormat.digits(restaurant.etaMinutes)} মিনিট',
                style: text.bodySmall,
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.slate40,
              ),
              const SizedBox(width: 3),
              Text(
                '${BnFormat.digits(restaurant.distanceKm.toStringAsFixed(1))} কিমি',
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.flag_outlined,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  restaurant.landmark,
                  style: text.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
