/// REST endpoints for the Phase 2 backend (Supabase edge functions or the
/// central API). Phase 1 runs fully on the mock repositories, so [baseUrl]
/// is injected via `--dart-define=PETUK_API_BASE_URL=...` when the backend
/// goes live — no code change needed in the UI layer.
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'PETUK_API_BASE_URL',
    defaultValue: '',
  );

  // Auth (FR-C01).
  static const String sendOtp = '/auth/otp/send';
  static const String verifyOtp = '/auth/otp/verify';

  // Catalog (FR-C02/03).
  static const String restaurants = '/restaurants';
  static const String validateCoupon = '/coupons/validate';

  // Orders (FR-C05/06).
  static const String orders = '/orders';

  /// `/orders/{id}` — build with `orderById(id)`.
  static String orderById(String id) => '/orders/$id';
}
