import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bd_phone.dart';
import '../models/otp_challenge.dart';
import '../models/user_session.dart';
import 'auth_repository.dart';

/// Phase 1 demo implementation of [AuthRepository].
///
/// Generates a real random OTP and enforces expiry, but "delivers" it via
/// [OtpChallenge.devCode] (shown as a demo banner in the UI) instead of a
/// paid SMS gateway. The session is persisted with SharedPreferences so
/// login survives app restarts. Swap with the API-backed repository in
/// Phase 2 without touching any UI code.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({required SharedPreferences prefs, Random? random})
      : _prefs = prefs,
        _random = random ?? Random.secure();

  static const String _phoneKey = 'petuk.session.phone';
  static const String _tokenKey = 'petuk.session.token';
  static const String _nameKey = 'petuk.session.name';

  final SharedPreferences _prefs;
  final Random _random;
  final Map<String, _OtpRecord> _challenges = <String, _OtpRecord>{};

  @override
  Future<OtpChallenge> sendOtp(String localPhone) async {
    // Simulated network latency of the SMS gateway.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!BdPhone.isValid(localPhone)) {
      throw const AuthException('সঠিক বাংলাদেশি মোবাইল নম্বর দিন।');
    }
    final String phone = BdPhone.toE164(localPhone);
    final String code = List<String>.generate(
      AppConstants.otpLength,
      (_) => _random.nextInt(10).toString(),
    ).join();
    _challenges[phone] = _OtpRecord(code: code, sentAt: DateTime.now());
    return OtpChallenge(
      phone: phone,
      expiresInSeconds: AppConstants.otpExpirySeconds,
      devCode: code,
    );
  }

  @override
  Future<UserSession> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final _OtpRecord? record = _challenges[phone];
    if (record == null) {
      throw const AuthException('ওটিপি পাঠানো হয়নি। আবার নম্বর দিন।');
    }
    final int age = DateTime.now().difference(record.sentAt).inSeconds;
    if (age > AppConstants.otpExpirySeconds) {
      _challenges.remove(phone);
      throw const AuthException('ওটিপির মেয়াদ শেষ। আবার পাঠান।');
    }
    if (record.code != code.trim()) {
      throw const AuthException('ভুল ওটিপি।', wrongCode: true);
    }
    _challenges.remove(phone);
    final String token =
        'demo-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}';
    await _prefs.setString(_phoneKey, phone);
    await _prefs.setString(_tokenKey, token);
    return UserSession(
      phone: phone,
      token: token,
      name: _prefs.getString(_nameKey),
    );
  }

  @override
  Future<UserSession?> currentSession() async {
    final String? phone = _prefs.getString(_phoneKey);
    final String? token = _prefs.getString(_tokenKey);
    if (phone == null || token == null || token.isEmpty) return null;
    return UserSession(
      phone: phone,
      token: token,
      name: _prefs.getString(_nameKey),
    );
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_phoneKey);
    await _prefs.remove(_tokenKey);
  }
}

class _OtpRecord {
  const _OtpRecord({required this.code, required this.sentAt});

  final String code;
  final DateTime sentAt;
}
