import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../data/models/food_category.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../location/pages/restaurants_map_page.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/shell_cubit.dart';
import '../widgets/category_chips.dart';
import '../widgets/location_selector.dart';
import '../widgets/promo_banner.dart';
import '../widgets/restaurant_card.dart';

/// Home: location selector ("বীরগঞ্জ পৌরসভা") + GPS/map trigger, search,
/// scrollable category chips, promo banners and the restaurant list.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (BuildContext context) => HomeBloc(
        catalogRepository: context.read<CatalogRepository>(),
      )..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _HomeHeader(),
            const SizedBox(height: 10),
            BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (HomeState p, HomeState c) =>
                  p.category != c.category,
              builder: (BuildContext context, HomeState state) {
                return CategoryChips(
                  selected: state.category,
                  onSelected: (FoodCategory? category) => context
                      .read<HomeBloc>()
                      .add(HomeCategoryChanged(category)),
                );
              },
            ),
            const SizedBox(height: 6),
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (BuildContext context, HomeState state) {
                  if (state.status == HomeStatus.initial ||
                      state.status == HomeStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state.status == HomeStatus.failure) {
                    return ErrorView(
                      message:
                          state.error ?? 'রেস্তোরাঁর তালিকা লোড করা যায়নি।',
                      onRetry: () => context
                          .read<HomeBloc>()
                          .add(const HomeRefreshRequested()),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<HomeBloc>()
                          .add(const HomeRefreshRequested());
                      await Future<void>.delayed(
                        const Duration(milliseconds: 700),
                      );
                    },
                    child: state.filtered.isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: const <Widget>[
                              SizedBox(height: 60),
                              EmptyState(
                                emoji: '🔍',
                                title: 'কিছু পাওয়া যায়নি',
                                message:
                                    'অন্য ক্যাটাগরি বা নাম দিয়ে খুঁজে দেখুন।',
                              ),
                            ],
                          )
                        : ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.only(top: 8, bottom: 24),
                            children: <Widget>[
                              PromoBanner(
                                onCakeTap: () => context
                                    .read<HomeBloc>()
                                    .add(
                                      const HomeCategoryChanged(
                                        FoodCategory.cake,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'আশেপাশের রেস্তোরাঁ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${BnFormat.digits(state.filtered.length)}টি',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.primaryDeep,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              for (final Restaurant restaurant
                                  in state.filtered)
                                RestaurantCard(
                                  restaurant: restaurant,
                                  distanceOverrideKm:
                                      (state.userLatitude != null &&
                                              state.userLongitude != null &&
                                              restaurant.hasCoordinates)
                                          ? LocationService.distanceKm(
                                              state.userLatitude!,
                                              state.userLongitude!,
                                              restaurant.latitude!,
                                              restaurant.longitude!,
                                            )
                                          : null,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.restaurant,
                                    arguments: restaurant,
                                  ),
                                ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppColors.primaryTint, AppColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _DotPatternPainter(
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: BlocBuilder<HomeBloc, HomeState>(
                      buildWhen: (HomeState p, HomeState c) =>
                          p.zone != c.zone || p.userLatitude != c.userLatitude,
                      builder: (BuildContext context, HomeState state) {
                        return Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => showLocationSelector(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primarySoft,
                                ),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    state.userLatitude != null
                                        ? Icons.my_location_rounded
                                        : Icons.location_on_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.zone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: AppColors.primaryDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (BuildContext context, HomeState state) {
                      return IconButton.filledTonal(
                        tooltip: 'রেস্তোরাঁ ম্যাপ',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.secondarySoft,
                          foregroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RestaurantsMapPage(
                              restaurants: state.restaurants,
                              userLatitude: state.userLatitude,
                              userLongitude: state.userLongitude,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 20),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder:
                        (BuildContext context, ProfileState profileState) {
                      final String emoji =
                          profileState.profile?.avatarEmoji ?? '😋';
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.read<ShellCubit>().setIndex(3),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 19),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (String query) {
                  context.read<HomeBloc>().add(HomeQueryChanged(query));
                  setState(() {});
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: 'খাবার বা রেস্তোরাঁ খুঁজুন…',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<HomeBloc>()
                                .add(const HomeQueryChanged(''));
                            setState(() {});
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle decorative dot grid per UI design skill background guidelines.
class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter({required this.color});

  static const double _spacing = 22;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
