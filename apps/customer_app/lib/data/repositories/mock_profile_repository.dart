import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/delivery_address.dart';
import '../models/user_profile.dart';
import '../models/user_session.dart';
import 'profile_repository.dart';

/// SharedPreferences-backed profile & saved addresses for Phase 1.
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _profilePrefix = 'petuk.profile.';
  static const String _sessionNameKey = 'petuk.session.name';

  final SharedPreferences _prefs;

  String _keyFor(String phone) => '$_profilePrefix$phone';

  @override
  Future<UserProfile> loadProfile(UserSession session) async {
    final String? raw = _prefs.getString(_keyFor(session.phone));
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        final UserProfile parsed = UserProfile.fromJson(decoded);
        if (parsed.phone == session.phone) {
          return parsed;
        }
      } catch (_) {
        // Fall back to fresh profile if stored JSON is malformed.
      }
    }
    final UserProfile initial = UserProfile(
      phone: session.phone,
      name: session.name ?? '',
      savedAddresses: <DeliveryAddress>[
        DeliveryAddress(
          id: 'addr-default',
          label: 'বাসা',
          recipientName: session.name ?? 'গ্রাহক',
          phone: session.phone,
          zone: AppConstants.defaultZone,
          area: 'কলেজ রোড, ২য় গলি',
          landmark: 'সোনালী ব্যাংকের পেছনে',
          latitude: AppConstants.birganjLat,
          longitude: AppConstants.birganjLng,
          isDefault: true,
        ),
      ],
    );
    await _persist(initial);
    return initial;
  }

  @override
  Future<UserProfile> updateProfile({
    required String phone,
    required String name,
    required String email,
    required String avatarEmoji,
    required String defaultZone,
    required bool smsNotifications,
  }) async {
    final UserProfile current = await _readOrEmpty(phone);
    final UserProfile updated = current.copyWith(
      name: name.trim(),
      email: email.trim(),
      avatarEmoji: avatarEmoji,
      defaultZone: defaultZone,
      smsNotifications: smsNotifications,
    );
    await _prefs.setString(_sessionNameKey, updated.name);
    await _persist(updated);
    return updated;
  }

  @override
  Future<UserProfile> saveAddress(
    String phone,
    DeliveryAddress address,
  ) async {
    final UserProfile current = await _readOrEmpty(phone);
    final String id = address.id ??
        'addr-${DateTime.now().millisecondsSinceEpoch}';
    final bool shouldBeDefault =
        address.isDefault || current.savedAddresses.isEmpty;

    final DeliveryAddress normalized = address.copyWith(
      id: id,
      phone: address.phone.isEmpty ? phone : address.phone,
      isDefault: shouldBeDefault,
    );

    final List<DeliveryAddress> list = <DeliveryAddress>[];
    bool replaced = false;
    for (final DeliveryAddress existing in current.savedAddresses) {
      if (existing.id == id) {
        list.add(normalized);
        replaced = true;
      } else {
        list.add(
          shouldBeDefault ? existing.copyWith(isDefault: false) : existing,
        );
      }
    }
    if (!replaced) {
      list.insert(0, normalized);
    }

    final UserProfile updated = current.copyWith(savedAddresses: list);
    await _persist(updated);
    return updated;
  }

  @override
  Future<UserProfile> deleteAddress(String phone, String addressId) async {
    final UserProfile current = await _readOrEmpty(phone);
    final List<DeliveryAddress> remaining = current.savedAddresses
        .where((DeliveryAddress a) => a.id != addressId)
        .toList();
    if (remaining.isNotEmpty &&
        !remaining.any((DeliveryAddress a) => a.isDefault)) {
      remaining[0] = remaining[0].copyWith(isDefault: true);
    }
    final UserProfile updated = current.copyWith(savedAddresses: remaining);
    await _persist(updated);
    return updated;
  }

  @override
  Future<UserProfile> setDefaultAddress(
    String phone,
    String addressId,
  ) async {
    final UserProfile current = await _readOrEmpty(phone);
    final List<DeliveryAddress> next = current.savedAddresses
        .map(
          (DeliveryAddress a) => a.copyWith(isDefault: a.id == addressId),
        )
        .toList();
    final UserProfile updated = current.copyWith(savedAddresses: next);
    await _persist(updated);
    return updated;
  }

  Future<UserProfile> _readOrEmpty(String phone) async {
    final String? raw = _prefs.getString(_keyFor(phone));
    if (raw != null && raw.isNotEmpty) {
      try {
        return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return UserProfile(phone: phone);
  }

  Future<void> _persist(UserProfile profile) async {
    await _prefs.setString(
      _keyFor(profile.phone),
      jsonEncode(profile.toJson()),
    );
  }
}
