import 'package:equatable/equatable.dart';

/// Result of requesting an SMS OTP.
///
/// [devCode] is only ever non-null in the Phase 1 demo backend so the
/// flow is testable without a live SMS gateway (Greenweb/Elitbuzz).
/// The real API must NEVER return the code.
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.phone,
    required this.expiresInSeconds,
    this.devCode,
  });

  /// E.164, e.g. +8801712345678.
  final String phone;
  final int expiresInSeconds;
  final String? devCode;

  @override
  List<Object?> get props => <Object?>[phone, expiresInSeconds, devCode];
}

/// Thrown for OTP send/verify failures with a Bangla message.
class AuthException implements Exception {
  const AuthException(this.message, {this.wrongCode = false});

  final String message;

  /// True only when the entered code did not match. Drives the
  /// 3-strikes → 5-minute lock rule (QA-01); expiry/network errors
  /// must NOT consume an attempt.
  final bool wrongCode;

  @override
  String toString() => 'AuthException: $message';
}
