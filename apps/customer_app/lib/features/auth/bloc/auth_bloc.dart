import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user_session.dart';
import '../../../data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// App launch — restore the persisted session (splash decision).
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Re-read the session after a successful OTP verification.
final class AuthSessionRefreshed extends AuthEvent {
  const AuthSessionRefreshed();
}

final class AuthSignedOut extends AuthEvent {
  const AuthSignedOut();
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum AuthStatus { unknown, authenticated, unauthenticated }

final class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.session});

  final AuthStatus status;
  final UserSession? session;

  @override
  List<Object?> get props => <Object?>[status, session];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// App-wide session bloc. The OTP screen owns the verification flow;
/// on success it fires [AuthSessionRefreshed] so this bloc picks up the
/// newly persisted session.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthStarted>(_onSessionRead);
    on<AuthSessionRefreshed>(_onSessionRead);
    on<AuthSignedOut>(_onSignedOut);
  }

  final AuthRepository _authRepository;

  Future<void> _onSessionRead(AuthEvent event, Emitter<AuthState> emit) async {
    final UserSession? session = await _authRepository.currentSession();
    if (isClosed) return;
    if (session == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } else {
      emit(AuthState(status: AuthStatus.authenticated, session: session));
    }
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    if (isClosed) return;
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
