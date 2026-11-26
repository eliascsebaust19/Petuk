import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/petuk_map_view.dart';
import '../../../data/models/restaurant.dart';
import '../../home/widgets/restaurant_card.dart';

/// Interactive Birganj restaurant map showing all partners, user GPS pin,
/// live distance, and Google Maps directions.
class RestaurantsMapPage extends StatefulWidget {
  const RestaurantsMapPage({
    super.key,
    required this.restaurants,
    this.userLatitude,
    this.userLongitude,
  });

  final List<Restaurant> restaurants;
  final double? userLatitude;
  final double? userLongitude;

  @override
  State<RestaurantsMapPage> createState() => _RestaurantsMapPageState();
}

class _RestaurantsMapPageState extends State<RestaurantsMapPage> {
  final MapController _mapController = MapController();
  Restaurant? _selected;
  LatLng? _userPoint;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.userLatitude != null && widget.userLongitude != null) {
      _userPoint = LatLng(widget.userLatitude!, widget.userLongitude!);
    }
    if (widget.restaurants.isNotEmpty) {
      _selected = widget.restaurants.first;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnGps() async {
    setState(() => _locating = true);
    try {
      final GpsFix fix = await LocationService.fetchCurrentGps();
      if (!mounted) return;
      final LatLng pt = LatLng(fix.latitude, fix.longitude);
      setState(() => _userPoint = pt);
      _mapController.move(pt, 15.5);
    } on LocationFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final LatLng initialCenter = _userPoint ??
        const LatLng(AppConstants.birganjLat, AppConstants.birganjLng);

    final List<Marker> markers = <Marker>[
      for (final Restaurant r in widget.restaurants)
        if (r.hasCoordinates)
          Marker(
            point: LatLng(r.latitude!, r.longitude!),
            width: 120,
            height: 66,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () {
                setState(() => _selected = r);
                _mapController.move(LatLng(r.latitude!, r.longitude!), 16);
              },
              child: PetukMapPin(
                icon: Icons.restaurant_rounded,
                color: _selected?.id == r.id
                    ? AppColors.accentWarm
                    : AppColors.primary,
                label: r.name,
                size: _selected?.id == r.id ? 42 : 34,
              ),
            ),
          ),
      if (_userPoint != null)
        Marker(
          point: _userPoint!,
          width: 90,
          height: 60,
          alignment: Alignment.topCenter,
          child: const PetukMapPin(
            icon: Icons.person_pin_circle_rounded,
            color: AppColors.info,
            label: 'আপনি',
            size: 36,
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('বীরগঞ্জ রেস্তোরাঁ ম্যাপ'),
        actions: <Widget>[
          IconButton(
            tooltip: 'আমার GPS অবস্থান',
            onPressed: _locating ? null : _centerOnGps,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PetukMapView(
            mapController: _mapController,
            center: initialCenter,
            zoom: 14.8,
            height: null,
            borderRadius: 0,
            markers: markers,
          ),
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _SelectedRestaurantSheet(
                  restaurant: _selected!,
                  userPoint: _userPoint,
                  text: text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedRestaurantSheet extends StatelessWidget {
  const _SelectedRestaurantSheet({
    required this.restaurant,
    required this.userPoint,
    required this.text,
  });

  final Restaurant restaurant;
  final LatLng? userPoint;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final double km = (userPoint != null && restaurant.hasCoordinates)
        ? LocationService.distanceKm(
            userPoint!.latitude,
            userPoint!.longitude,
            restaurant.latitude!,
            restaurant.longitude!,
          )
        : restaurant.distanceKm;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
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
                    const SizedBox(height: 2),
                    Text(
                      '${restaurant.landmark} • ${BnFormat.digits(km.toStringAsFixed(1))} কিমি • ${BnFormat.digits(restaurant.etaMinutes)} মিনিট',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (restaurant.hasCoordinates)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => LocationService.openDirectionsInGoogleMaps(
                      destLat: restaurant.latitude!,
                      destLng: restaurant.longitude!,
                      originLat: userPoint?.latitude,
                      originLng: userPoint?.longitude,
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Google Maps'),
                  ),
                ),
              if (restaurant.hasCoordinates) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.restaurant,
                    arguments: restaurant,
                  ),
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                  label: const Text('মেনু দেখুন'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
