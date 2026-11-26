import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/bn_format.dart';
import '../../../data/models/otp_challenge.dart';
import '../../../data/models/user_session.dart';
import '../../../data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Starts the 60-second resend countdown for the just-sent code.
final class OtpStarted extends OtpEvent {
  const OtpStarted();
}

final class OtpCodeChanged extends OtpEvent {
  const OtpCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

final class OtpVerifyRequested extends OtpEvent {
  const OtpVerifyRequested();
}

final class OtpResendRequested extends OtpEvent {
  const OtpResendRequested();
}

final class _OtpTicked extends OtpEvent {
  const _OtpTicked();
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum OtpStatus { idle, sending, verifying, failure, locked, success }

final class OtpState extends Equatable {
  const OtpState({
    this.code = '',
    this.status = OtpStatus.idle,
    this.resendSeconds = AppConstants.otpResendSeconds,
    this.lockSeconds = 0,
    this.attemptsUsed = 0,
    this.error,
    this.devCode,
    this.session,
  });

  final String code;
  final OtpStatus status;

  /// Seconds until "আবার পাঠান" unlocks (FR-C01: 60s timer).
  final int resendSeconds;

  /// Seconds remaining on the 5-minute lock (QA-01), 0 = unlocked.
  final int lockSeconds;
  final int attemptsUsed;
  final String? error;

  /// Demo-mode code from the mock SMS gateway (never in production).
  final String? devCode;

  /// Set exactly once, on successful verification.
  final UserSession? session;

  int get attemptsLeft => AppConstants.otpMaxAttempts - attemptsUsed;

  bool get isLocked => lockSeconds > 0;

  bool get canResend =>
      resendSeconds == 0 &&
      lockSeconds == 0 &&
      status != OtpStatus.sending &&
      status != OtpStatus.verifying &&
      status != OtpStatus.success;

  bool get isBusy =>
      status == OtpStatus.sending || status == OtpStatus.verifying;

  static const Object _unset = Object();

  OtpState copyWith({
    String? code,
    OtpStatus? status,
    int? resendSeconds,
    int? lockSeconds,
    int? attemptsUsed,
    Object? error = _unset,
    Object? devCode = _unset,
    UserSession? session,
  }) {
    return OtpState(
      code: code ?? this.code,
      status: status ?? this.status,
      resendSeconds: resendSeconds ?? this.resendSeconds,
      lockSeconds: lockSeconds ?? this.lockSeconds,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      error: identical(error, _unset) ? this.error : error as String?,
      devCode: identical(devCode, _unset) ? this.devCode : devCode as String?,
      session: session ?? this.session,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        code,
        status,
        resendSeconds,
        lockSeconds,
        attemptsUsed,
        error,
        devCode,
        session,
      ];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// Owns the verification step for one phone number: countdown, resend,
/// auto-submit on 6 digits, and the 3-wrong-attempts → 5-minute lock.
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required AuthRepository authRepository,
    required OtpChallenge challenge,
  })  : _authRepository = authRepository,
        _phone = challenge.phone,
        super(OtpState(devCode: challenge.devCode)) {
    on<OtpStarted>(_onStarted);
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpVerifyRequested>(_onVerifyRequested);
    on<OtpResendRequested>(_onResendRequested);
    on<_OtpTicked>(_onTicked);
  }

  final AuthRepository _authRepository;

  /// E.164 phone this challenge belongs to.
  final String _phone;

  Timer? _timer;

  void _onStarted(OtpStarted event, Emitter<OtpState> emit) {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const _OtpTicked()),
    );
    emit(state.copyWith(resendSeconds: AppConstants.otpResendSeconds));
  }

  void _onTicked(_OtpTicked event, Emitter<OtpState> emit) {
    if (state.status == OtpStatus.success) return;
    final int resend =
        state.resendSeconds > 0 ? state.resendSeconds - 1 : 0;
    int lock = state.lockSeconds > 0 ? state.lockSeconds - 1 : 0;
    if (state.lockSeconds > 0 && lock == 0) {
      // Lock expired — attempts reset, user may try again.
      lock = 0;
      emit(
        state.copyWith(
          resendSeconds: resend,
          lockSeconds: 0,
          attemptsUsed: 0,
          status: OtpStatus.idle,
          code: '',
          error: null,
        ),
      );
      return;
    }
    if (resend != state.resendSeconds || lock != state.lockSeconds) {
      emit(state.copyWith(resendSeconds: resend, lockSeconds: lock));
    }
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    if (state.isLocked || state.isBusy || state.status == OtpStatus.success) {
      return;
    }
    final String digitsOnly = event.code.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digitsOnly.length > AppConstants.otpLength
        ? digitsOnly.substring(0, AppConstants.otpLength)
        : digitsOnly;
    emit(state.copyWith(code: trimmed, status: OtpStatus.idle, error: null));
    // Auto-submit when the 6th digit lands (supports SMS autofill paste).
    if (trimmed.length == AppConstants.otpLength) {
      add(const OtpVerifyRequested());
    }
  }

  Future<void> _onVerifyRequested(
    OtpVerifyRequested event,
    Emitter<OtpState> emit,
  ) async {
    if (state.isLocked || state.isBusy || state.status == OtpStatus.success) {
      return;
    }
    if (state.code.length != AppConstants.otpLength) {
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          error: '৬ ডিজিটের ওটিপি দিন।',
        ),
      );
      return;
    }
    emit(state.copyWith(status: OtpStatus.verifying, error: null));
    try {
      final UserSession session =
          await _authRepository.verifyOtp(phone: _phone, code: state.code);
      if (isClosed) return;
      _timer?.cancel();
      emit(state.copyWith(status: OtpStatus.success, session: session));
    } on AuthException catch (error) {
      if (isClosed) return;
      if (error.wrongCode) {
        _handleWrongCode(emit);
      } else {
        emit(
          state.copyWith(
            status: OtpStatus.failure,
            code: '',
            error: error.message,
          ),
        );
      }
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          error: 'যাচাই করা যায়নি। আবার চেষ্টা করুন।',
        ),
      );
    }
  }

  void _handleWrongCode(Emitter<OtpState> emit) {
    final int attempts = state.attemptsUsed + 1;
    if (attempts >= AppConstants.otpMaxAttempts) {
      emit(
        state.copyWith(
          status: OtpStatus.locked,
          attemptsUsed: attempts,
          lockSeconds: AppConstants.otpLockSeconds,
          code: '',
          error:
              '৩ বার ভুল ওটিপি। নিরাপত্তার জন্য ৫ মিনিট চেষ্টা বন্ধ রাখা হলো।',
        ),
      );
    } else {
      final int left = AppConstants.otpMaxAttempts - attempts;
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          attemptsUsed: attempts,
          code: '',
          error:
              'ভুল ওটিপি। আর ${BnFormat.digits(left)} বার চেষ্টা করা যাবে।',
        ),
      );
    }
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState> emit,
  ) async {
    if (!state.canResend) return;
    emit(state.copyWith(status: OtpStatus.sending, error: null));
    try {
      // +8801XXXXXXXXX → 01XXXXXXXXX for the send API.
      final OtpChallenge challenge =
          await _authRepository.sendOtp('0${_phone.substring(4)}');
      if (isClosed) return;
      emit(
        state.copyWith(
          status: OtpStatus.idle,
          resendSeconds: AppConstants.otpResendSeconds,
          devCode: challenge.devCode,
          code: '',
          error: null,
        ),
      );
    } on AuthException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: OtpStatus.failure, error: error.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: OtpStatus.failure,
          error: 'আবার পাঠানো যায়নি। কিছুক্ষণ পর চেষ্টা করুন।',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
