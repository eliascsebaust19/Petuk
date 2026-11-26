import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Interactive map widget (works on Web, Android & iOS without requiring a
/// paid API key) supporting custom pins, polylines, tap-to-pick, and zoom.
class PetukMapView extends StatelessWidget {
  const PetukMapView({
    super.key,
    required this.center,
    this.zoom = 15,
    this.mapController,
    this.markers = const <Marker>[],
    this.polylines = const <Polyline>[],
    this.onTap,
    this.height = 240,
    this.borderRadius = 16,
    this.interactive = true,
  });

  final LatLng center;
  final double zoom;
  final MapController? mapController;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final void Function(TapPosition tapPosition, LatLng point)? onTap;
  final double? height;
  final double borderRadius;
  final bool interactive;

  static LatLng get birganjCenter =>
      const LatLng(AppConstants.birganjLat, AppConstants.birganjLng);

  @override
  Widget build(BuildContext context) {
    final Widget map = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              minZoom: 11,
              maxZoom: 18,
              interactionOptions: InteractionOptions(
                flags: interactive
                    ? InteractiveFlag.all
                    : InteractiveFlag.none,
              ),
              onTap: onTap,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.petuk.foodie_birganj',
                maxNativeZoom: 19,
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            left: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap • CARTO',
                style: TextStyle(fontSize: 9, color: AppColors.slate60),
              ),
            ),
          ),
        ],
      ),
    );

    if (height == null) return map;
    return SizedBox(height: height, child: map);
  }
}

/// Reusable stylized map pin for delivery, restaurant, GPS, or rider.
class PetukMapPin extends StatelessWidget {
  const PetukMapPin({
    super.key,
    required this.icon,
    required this.color,
    this.label,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null && label!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.slate,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.52),
        ),
      ],
    );
  }
}
