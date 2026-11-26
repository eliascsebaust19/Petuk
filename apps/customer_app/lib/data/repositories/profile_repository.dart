import '../models/delivery_address.dart';
import '../models/user_profile.dart';
import '../models/user_session.dart';

/// Customer profile & saved-addresses contract.
///
/// Phase 1: [MockProfileRepository] backed by SharedPreferences.
/// Phase 2: swap with REST API calls via [ApiClient].
abstract interface class ProfileRepository {
  Future<UserProfile> loadProfile(UserSession session);

  Future<UserProfile> updateProfile({
    required String phone,
    required String name,
    required String email,
    required String avatarEmoji,
    required String defaultZone,
    required bool smsNotifications,
  });

  Future<UserProfile> saveAddress(String phone, DeliveryAddress address);

  Future<UserProfile> deleteAddress(String phone, String addressId);

  Future<UserProfile> setDefaultAddress(String phone, String addressId);
}
