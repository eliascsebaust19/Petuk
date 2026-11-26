/// Global business rules for the Foodie Birganj customer app.
///
/// Values mirror the finalized SRS (`birganj_4_apps_srs_report.pdf` and
/// `birganj_food_delivery_srs_report.pdf`).
abstract final class AppConstants {
  static const String appName = 'Foodie Birganj';
  static const String brandName = 'Petuk';
  static const String tagline = 'বীরগঞ্জের সেরা স্বাদ আপনার দরজায়';

  /// Flat delivery fee in BDT charged on every non-empty order (FR-C04/05).
  static const int deliveryFee = 30;

  /// Maximum units allowed per cart line.
  static const int maxItemQuantity = 20;

  // ---------------------------------------------------------------------
  // OTP rules — FR-C01 and QA-01.
  // ---------------------------------------------------------------------

  /// 6-digit SMS OTP.
  static const int otpLength = 6;

  /// Resend cooldown timer (seconds).
  static const int otpResendSeconds = 60;

  /// Wrong attempts allowed before the temporary lock.
  static const int otpMaxAttempts = 3;

  /// Lock duration after too many wrong attempts (5 minutes, QA-01).
  static const int otpLockSeconds = 300;

  /// A sent OTP stays valid for 5 minutes.
  static const int otpExpirySeconds = 300;

  // ---------------------------------------------------------------------
  // Landmark-first delivery zones — FR-C04.
  // ---------------------------------------------------------------------

  static const String defaultZone = 'বীরগঞ্জ পৌরসভা';

  /// Zone 1 (live service area, 30–45 minute promise).
  static const List<String> serviceZones = <String>[
    'বীরগঞ্জ পৌরসভা',
    'কলেজ মোড়',
    'হাসপাতাল রোড',
    'পুরাতন বাজার',
    'মহাসড়ক সংলগ্ন এলাকা',
  ];

  /// Zone 2 — visible but disabled ("শীঘ্রই আসছে"), per the expansion plan.
  static const List<String> upcomingZones = <String>[
    'ঝাড়বাড়ী বাজার',
    'গোলাপগঞ্জ বাজার',
  ];

  // ---------------------------------------------------------------------
  // Birganj GPS & Google Maps defaults.
  // ---------------------------------------------------------------------

  /// Birganj Pourashava center (Dinajpur, Bangladesh).
  static const double birganjLat = 25.8565;
  static const double birganjLng = 88.6510;
  static const double maxDeliveryRadiusKm = 12.0;

  /// Approximate zone centroids for automatic GPS → zone snapping.
  static const Map<String, ({double lat, double lng})> serviceZoneCenters =
      <String, ({double lat, double lng})>{
    'বীরগঞ্জ পৌরসভা': (lat: 25.8565, lng: 88.6510),
    'কলেজ মোড়': (lat: 25.8602, lng: 88.6478),
    'হাসপাতাল রোড': (lat: 25.8538, lng: 88.6552),
    'পুরাতন বাজার': (lat: 25.8594, lng: 88.6536),
    'মহাসড়ক সংলগ্ন এলাকা': (lat: 25.8515, lng: 88.6458),
  };

  // ---------------------------------------------------------------------
  // Phase-1 manual operations contacts.
  //
  // These are demo numbers. Replace with the real ops SIM, bKash merchant
  // and Nagad merchant numbers before the Play Store launch.
  // ---------------------------------------------------------------------

  static const String supportPhone = '+8801700000000';
  static const String bkashMerchantNumber = '01712345678';
  static const String nagadMerchantNumber = '01812345678';

  // ---------------------------------------------------------------------
  // Demo pacing of the mock order pipeline (seconds after placement).
  // The real backend will push these transitions via FCM / realtime rows.
  // ---------------------------------------------------------------------

  static const int mockPreparingAfterSeconds = 15;
  static const int mockOnTheWayAfterSeconds = 40;
  static const int mockDeliveredAfterSeconds = 80;
}
