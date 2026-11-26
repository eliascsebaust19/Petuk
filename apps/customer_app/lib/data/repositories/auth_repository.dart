import '../models/otp_challenge.dart';
import '../models/user_session.dart';

/// Passwordless phone-OTP authentication (SRS FR-C01).
///
/// Phase 1 implementation: [MockAuthRepository] (demo SMS).
/// Phase 2 implementation: same contract over Firebase Auth or the
/// Greenweb BD / Elitbuzz SMS gateway via [ApiClient].
abstract interface class AuthRepository {
  /// Sends a 6-digit SMS OTP to [localPhone] (`01XXXXXXXXX`).
  ///
  /// Throws [AuthException] with a Bangla message on failure.
  Future<OtpChallenge> sendOtp(String localPhone);

  /// Verifies [code] for [phone] (E.164) and creates a persisted session.
  Future<UserSession> verifyOtp({
    required String phone,
    required String code,
  });

  /// The persisted session, or null when signed out.
  Future<UserSession?> currentSession();

  /// Clears the persisted session.
  Future<void> signOut();
}
