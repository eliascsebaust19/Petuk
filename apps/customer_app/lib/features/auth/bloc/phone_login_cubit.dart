import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/bd_phone.dart';
import '../../../data/models/otp_challenge.dart';
import '../../../data/repositories/auth_repository.dart';

enum PhoneLoginStatus { editing, submitting, sent, failure }

final class PhoneLoginState extends Equatable {
  const PhoneLoginState._({required this.status, this.challenge, this.error});

  const PhoneLoginState.editing() : this._(status: PhoneLoginStatus.editing);

  const PhoneLoginState.submitting()
      : this._(status: PhoneLoginStatus.submitting);

  const PhoneLoginState.sent(OtpChallenge challenge)
      : this._(status: PhoneLoginStatus.sent, challenge: challenge);

  const PhoneLoginState.failure(String error)
      : this._(status: PhoneLoginStatus.failure, error: error);

  final PhoneLoginStatus status;
  final OtpChallenge? challenge;
  final String? error;

  @override
  List<Object?> get props => <Object?>[status, challenge, error];
}

/// Owns the phone-number step: validate → send OTP → hand the challenge
/// to the OTP screen.
class PhoneLoginCubit extends Cubit<PhoneLoginState> {
  PhoneLoginCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const PhoneLoginState.editing());

  final AuthRepository _authRepository;

  /// [localPhone] is the raw 11-digit input (`01XXXXXXXXX`).
  Future<void> submit(String localPhone) async {
    if (state.status == PhoneLoginStatus.submitting) return;
    final String? validationError = BdPhone.validate(localPhone);
    if (validationError != null) {
      emit(PhoneLoginState.failure(validationError));
      return;
    }
    emit(const PhoneLoginState.submitting());
    try {
      final OtpChallenge challenge =
          await _authRepository.sendOtp(localPhone.trim());
      if (isClosed) return;
      emit(PhoneLoginState.sent(challenge));
    } on AuthException catch (error) {
      if (isClosed) return;
      emit(PhoneLoginState.failure(error.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        const PhoneLoginState.failure(
          'ওটিপি পাঠানো যায়নি। আবার চেষ্টা করুন।',
        ),
      );
    }
  }

  /// Back to the editing state (e.g. user returned from the OTP screen).
  void reset() {
    if (isClosed) return;
    emit(const PhoneLoginState.editing());
  }
}
