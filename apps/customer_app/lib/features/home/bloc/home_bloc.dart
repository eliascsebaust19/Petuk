import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/food_category.dart';
import '../../../data/models/food_item.dart';
import '../../../data/models/restaurant.dart';
import '../../../data/repositories/catalog_repository.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

/// `null` category = the "সব" chip.
final class HomeCategoryChanged extends HomeEvent {
  const HomeCategoryChanged(this.category);

  final FoodCategory? category;

  @override
  List<Object?> get props => <Object?>[category];
}

final class HomeQueryChanged extends HomeEvent {
  const HomeQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

final class HomeZoneChanged extends HomeEvent {
  const HomeZoneChanged(this.zone);

  final String zone;

  @override
  List<Object?> get props => <Object?>[zone];
}

final class HomeGpsUpdated extends HomeEvent {
  const HomeGpsUpdated({
    required this.zone,
    required this.latitude,
    required this.longitude,
  });

  final String zone;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => <Object?>[zone, latitude, longitude];
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum HomeStatus { initial, loading, ready, failure }

final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.restaurants = const <Restaurant>[],
    this.filtered = const <Restaurant>[],
    this.category,
    this.query = '',
    this.zone = AppConstants.defaultZone,
    this.userLatitude,
    this.userLongitude,
    this.error,
  });

  final HomeStatus status;
  final List<Restaurant> restaurants;

  /// [restaurants] after category + search filtering.
  final List<Restaurant> filtered;
  final FoodCategory? category;
  final String query;
  final String zone;
  final double? userLatitude;
  final double? userLongitude;
  final String? error;

  static const Object _unset = Object();

  HomeState copyWith({
    HomeStatus? status,
    List<Restaurant>? restaurants,
    List<Restaurant>? filtered,
    Object? category = _unset,
    String? query,
    String? zone,
    double? userLatitude,
    double? userLongitude,
    Object? error = _unset,
  }) {
    return HomeState(
      status: status ?? this.status,
      restaurants: restaurants ?? this.restaurants,
      filtered: filtered ?? this.filtered,
      category:
          identical(category, _unset) ? this.category : category as FoodCategory?,
      query: query ?? this.query,
      zone: zone ?? this.zone,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        restaurants,
        filtered,
        category,
        query,
        zone,
        userLatitude,
        userLongitude,
        error,
      ];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// Catalog browsing: load once, then filter client-side (the launch
/// catalog is 8–10 restaurants — instant, offline-friendly, no debounce
/// needed at this size).
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(const HomeState()) {
    on<HomeStarted>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
    on<HomeCategoryChanged>(
      (HomeCategoryChanged event, Emitter<HomeState> emit) =>
          emit(_applyFilters(state.copyWith(category: event.category))),
    );
    on<HomeQueryChanged>(
      (HomeQueryChanged event, Emitter<HomeState> emit) =>
          emit(_applyFilters(state.copyWith(query: event.query))),
    );
    on<HomeZoneChanged>(
      (HomeZoneChanged event, Emitter<HomeState> emit) =>
          emit(state.copyWith(zone: event.zone)),
    );
    on<HomeGpsUpdated>(
      (HomeGpsUpdated event, Emitter<HomeState> emit) => emit(
        state.copyWith(
          zone: event.zone,
          userLatitude: event.latitude,
          userLongitude: event.longitude,
        ),
      ),
    );
  }

  final CatalogRepository _catalogRepository;

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, error: null));
    try {
      final List<Restaurant> restaurants =
          await _catalogRepository.fetchRestaurants();
      if (isClosed) return;
      emit(
        _applyFilters(
          state.copyWith(status: HomeStatus.ready, restaurants: restaurants),
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          error: 'রেস্তোরাঁর তালিকা লোড করা যায়নি।',
        ),
      );
    }
  }

  HomeState _applyFilters(HomeState source) {
    final String query = source.query.trim().toLowerCase();
    final List<Restaurant> filtered = source.restaurants.where(
      (Restaurant restaurant) {
        if (source.category != null &&
            !restaurant.categories.contains(source.category)) {
          return false;
        }
        if (query.isEmpty) return true;
        if (restaurant.name.toLowerCase().contains(query) ||
            restaurant.cuisine.toLowerCase().contains(query)) {
          return true;
        }
        return restaurant.menu.any(
          (FoodItem food) => food.name.toLowerCase().contains(query),
        );
      },
    ).toList();
    return source.copyWith(filtered: filtered);
  }
}
