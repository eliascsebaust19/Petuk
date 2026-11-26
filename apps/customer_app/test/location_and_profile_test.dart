import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_birganj/core/constants/app_constants.dart';
import 'package:foodie_birganj/core/services/location_service.dart';
import 'package:foodie_birganj/data/models/delivery_address.dart';
import 'package:foodie_birganj/data/models/user_session.dart';
import 'package:foodie_birganj/data/repositories/mock_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocationService (GPS & Birganj zone mapping)', () {
    test('distanceKm is zero for identical coordinates and accurate nearby',
        () {
      expect(
        LocationService.distanceKm(
          AppConstants.birganjLat,
          AppConstants.birganjLng,
          AppConstants.birganjLat,
          AppConstants.birganjLng,
        ),
        closeTo(0, 0.001),
      );

      final double dist = LocationService.distanceKm(
        25.8565,
        88.6510,
        25.8602,
        88.6478,
      );
      expect(dist, greaterThan(0.3));
      expect(dist, lessThan(1.0));
    });

    test('nearestServiceZone resolves Birganj zones accurately', () {
      expect(
        LocationService.nearestServiceZone(25.8602, 88.6478),
        'কলেজ মোড়',
      );
      expect(
        LocationService.nearestServiceZone(25.8538, 88.6552),
        'হাসপাতাল রোড',
      );
      expect(
        LocationService.nearestServiceZone(25.8594, 88.6536),
        'পুরাতন বাজার',
      );
    });

    test('fromCoordinates marks far coordinates as outside Birganj', () {
      final GpsFix dhakaFix = LocationService.fromCoordinates(23.8103, 90.4125);
      expect(dhakaFix.isInsideBirganj, isFalse);

      final GpsFix birganjFix = LocationService.fromCoordinates(
        AppConstants.birganjLat,
        AppConstants.birganjLng,
      );
      expect(birganjFix.isInsideBirganj, isTrue);
    });
  });

  group('MockProfileRepository (profile & saved addresses)', () {
    late MockProfileRepository repo;
    const UserSession session = UserSession(
      phone: '+8801712345678',
      token: 'test-token',
      name: 'রফিকুল ইসলাম',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      repo = MockProfileRepository(prefs: prefs);
    });

    test('creates initial profile with default Birganj address', () async {
      final profile = await repo.loadProfile(session);
      expect(profile.phone, session.phone);
      expect(profile.name, 'রফিকুল ইসলাম');
      expect(profile.savedAddresses, isNotEmpty);
      expect(profile.defaultAddress?.hasCoordinates, isTrue);
    });

    test('updates profile info and persists across reload', () async {
      await repo.loadProfile(session);
      await repo.updateProfile(
        phone: session.phone,
        name: 'তানভীর আহমেদ',
        email: 'tanvir@example.com',
        avatarEmoji: '🍛',
        defaultZone: 'কলেজ মোড়',
        smsNotifications: false,
      );

      final reloaded = await repo.loadProfile(session);
      expect(reloaded.name, 'তানভীর আহমেদ');
      expect(reloaded.email, 'tanvir@example.com');
      expect(reloaded.avatarEmoji, '🍛');
      expect(reloaded.defaultZone, 'কলেজ মোড়');
      expect(reloaded.smsNotifications, isFalse);
    });

    test('saves new GPS address, switches default, and deletes cleanly',
        () async {
      await repo.loadProfile(session);
      final afterAdd = await repo.saveAddress(
        session.phone,
        const DeliveryAddress(
          label: 'অফিস',
          recipientName: 'তানভীর আহমেদ',
          phone: '+8801712345678',
          zone: 'হাসপাতাল রোড',
          area: 'উপজেলা স্বাস্থ্য কমপ্লেক্স রোড',
          landmark: 'মেইন গেটের সামনে',
          latitude: 25.8538,
          longitude: 88.6552,
          isDefault: true,
        ),
      );
      expect(afterAdd.savedAddresses.length, 2);
      expect(afterAdd.defaultAddress?.label, 'অফিস');

      final String officeId = afterAdd.defaultAddress!.id!;
      final afterDelete = await repo.deleteAddress(session.phone, officeId);
      expect(afterDelete.savedAddresses.length, 1);
      expect(afterDelete.defaultAddress?.isDefault, isTrue);
    });
  });
}
