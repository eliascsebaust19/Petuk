import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/petuk_map_view.dart';
import '../../../core/widgets/primary_button.dart';

/// Returned by [MapPickerPage] when the user confirms a pin.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.distanceFromBirganjKm,
  });

  final double latitude;
  final double longitude;
  final String zone;
  final double distanceFromBirganjKm;
}

/// Interactive map screen to drop a delivery pin, detect live GPS, and
/// preview the location in Google Maps.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZone,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialZone;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  late LatLng _selected;
  late GpsFix _fix;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final ({double lat, double lng})? zoneCenter = widget.initialZone != null
        ? AppConstants.serviceZoneCenters[widget.initialZone]
        : null;
    final double lat =
        widget.initialLatitude ?? zoneCenter?.lat ?? AppConstants.birganjLat;
    final double lng =
        widget.initialLongitude ?? zoneCenter?.lng ?? AppConstants.birganjLng;
    _selected = LatLng(lat, lng);
    _fix = LocationService.fromCoordinates(lat, lng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point) {
    setState(() {
      _selected = point;
      _fix = LocationService.fromCoordinates(point.latitude, point.longitude);
    });
  }

  Future<void> _useCurrentGps() async {
    setState(() => _locating = true);
    try {
      final GpsFix gps = await LocationService.fetchCurrentGps();
      if (!mounted) return;
      final LatLng point = LatLng(gps.latitude, gps.longitude);
      setState(() {
        _selected = point;
        _fix = gps;
      });
      _mapController.move(point, 16);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS লোকেশন শনাক্ত হয়েছে • জোন: ${gps.zone}'),
        ),
      );
    } on LocationFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    final bool ok = await LocationService.openInGoogleMaps(
      _selected.latitude,
      _selected.longitude,
      label: _fix.zone,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps খোলা যায়নি।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ম্যাপে লোকেশন বাছুন'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _openGoogleMaps,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Google Maps'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                PetukMapView(
                  mapController: _mapController,
                  center: _selected,
                  zoom: 15.5,
                  height: null,
                  borderRadius: 0,
                  onTap: (TapPosition _, LatLng point) => _selectPoint(point),
                  markers: <Marker>[
                    Marker(
                      point: _selected,
                      width: 140,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: PetukMapPin(
                        icon: Icons.location_on_rounded,
                        color: AppColors.primary,
                        label: _fix.zone,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
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
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ম্যাপে ট্যাপ করে আপনার ডেলিভারি পিন বসান বা GPS ব্যবহার করুন',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.slate,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'gps_fab',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primaryDark,
                    onPressed: _locating ? null : _useCurrentGps,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(
                      _locating ? 'খোঁজা হচ্ছে…' : 'আমার GPS',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'শনাক্তকৃত জোন: ${_fix.zone}',
                          style: text.labelMedium?.copyWith(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${BnFormat.digits(_fix.distanceFromBirganjKm.toStringAsFixed(1))} কিমি',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'অবস্থান: ${_selected.latitude.toStringAsFixed(5)}, ${_selected.longitude.toStringAsFixed(5)}',
                    style: text.labelSmall,
                  ),
                  if (!_fix.isInsideBirganj) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      'সতর্কতা: পিনটি বীরগঞ্জ পৌর এলাকার বাইরে — ডেলিভারি সীমিত হতে পারে।',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'এই লোকেশন নিশ্চিত করুন',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      Navigator.of(context).pop(
                        PickedLocation(
                          latitude: _selected.latitude,
                          longitude: _selected.longitude,
                          zone: _fix.zone,
                          distanceFromBirganjKm: _fix.distanceFromBirganjKm,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
