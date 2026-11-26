import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Result of a live GPS fix resolved to a Birganj delivery zone.
class GpsFix {
  const GpsFix({
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.distanceFromBirganjKm,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final String zone;
  final double distanceFromBirganjKm;
  final double? accuracyMeters;

  bool get isInsideBirganj =>
      distanceFromBirganjKm <= AppConstants.maxDeliveryRadiusKm;
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cross-platform GPS + Birganj zone matching + Google Maps launcher.
abstract final class LocationService {
  /// Requests location permission if needed and returns the current GPS fix.
  ///
  /// Throws [LocationFailure] with a localized Bangla message if disabled or
  /// denied.
  static Future<GpsFix> fetchCurrentGps() async {
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationFailure(
        'ডিভাইসের GPS / লোকেশন সেবা বন্ধ আছে। চালু করে আবার চেষ্টা করুন।',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'লোকেশন অনুমতি দেওয়া হয়নি। অনুগ্রহ করে অনুমতি দিন।',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'লোকেশন অনুমতি স্থায়ীভাবে বন্ধ। সেটিংস থেকে চালু করুন।',
      );
    }

    try {
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return fromCoordinates(
        pos.latitude,
        pos.longitude,
        accuracyMeters: pos.accuracy,
      );
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(
        'GPS লোকেশন পাওয়া যায়নি। ম্যাপ থেকে পিন বসান।',
      );
    }
  }

  /// Resolves arbitrary coordinates into a [GpsFix] with nearest zone & distance.
  static GpsFix fromCoordinates(
    double latitude,
    double longitude, {
    double? accuracyMeters,
  }) {
    final String zone = nearestServiceZone(latitude, longitude);
    final double dist = distanceKm(
      latitude,
      longitude,
      AppConstants.birganjLat,
      AppConstants.birganjLng,
    );
    return GpsFix(
      latitude: latitude,
      longitude: longitude,
      zone: zone,
      distanceFromBirganjKm: dist,
      accuracyMeters: accuracyMeters,
    );
  }

  /// Finds the closest active Birganj delivery zone centroid.
  static String nearestServiceZone(double latitude, double longitude) {
    String bestZone = AppConstants.defaultZone;
    double bestDist = double.infinity;
    for (final MapEntry<String, ({double lat, double lng})> entry
        in AppConstants.serviceZoneCenters.entries) {
      final double d = distanceKm(
        latitude,
        longitude,
        entry.value.lat,
        entry.value.lng,
      );
      if (d < bestDist) {
        bestDist = d;
        bestZone = entry.key;
      }
    }
    return bestZone;
  }

  /// Haversine distance in kilometers.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  /// Opens a pin in Google Maps (app or web).
  static Future<bool> openInGoogleMaps(
    double latitude,
    double longitude, {
    String? label,
  }) async {
    final String query = label != null && label.trim().isNotEmpty
        ? '$latitude,$longitude (${Uri.encodeComponent(label.trim())})'
        : '$latitude,$longitude';
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens Google Maps turn-by-turn directions from origin to destination.
  static Future<bool> openDirectionsInGoogleMaps({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) async {
    final String originParam = (originLat != null && originLng != null)
        ? '&origin=$originLat,$originLng'
        : '';
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$originParam'
      '&destination=$destLat,$destLng&travelmode=driving',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
