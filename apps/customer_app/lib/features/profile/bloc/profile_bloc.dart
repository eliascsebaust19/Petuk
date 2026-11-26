import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/delivery_address.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/user_session.dart';
import '../../../data/repositories/profile_repository.dart';

// ---------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded(this.session);

  final UserSession session;

  @override
  List<Object?> get props => <Object?>[session];
}

final class ProfileCleared extends ProfileEvent {
  const ProfileCleared();
}

final class ProfileInfoUpdated extends ProfileEvent {
  const ProfileInfoUpdated({
    required this.name,
    required this.email,
    required this.avatarEmoji,
    required this.defaultZone,
    required this.smsNotifications,
  });

  final String name;
  final String email;
  final String avatarEmoji;
  final String defaultZone;
  final bool smsNotifications;

  @override
  List<Object?> get props =>
      <Object?>[name, email, avatarEmoji, defaultZone, smsNotifications];
}

final class ProfileAddressSaved extends ProfileEvent {
  const ProfileAddressSaved(this.address);

  final DeliveryAddress address;

  @override
  List<Object?> get props => <Object?>[address];
}

final class ProfileAddressDeleted extends ProfileEvent {
  const ProfileAddressDeleted(this.addressId);

  final String addressId;

  @override
  List<Object?> get props => <Object?>[addressId];
}

final class ProfileDefaultAddressSelected extends ProfileEvent {
  const ProfileDefaultAddressSelected(this.addressId);

  final String addressId;

  @override
  List<Object?> get props => <Object?>[addressId];
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

enum ProfileStatus { initial, loading, ready, saving, failure }

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.message,
  });

  final ProfileStatus status;
  final UserProfile? profile;
  final String? message;

  static const Object _unset = Object();

  ProfileState copyWith({
    ProfileStatus? status,
    Object? profile = _unset,
    Object? message = _unset,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as UserProfile?,
      message: identical(message, _unset) ? this.message : message as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, profile, message];
}

// ---------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------

/// Manages customer profile, preferences, and saved delivery addresses.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileRepository profileRepository})
      : _repository = profileRepository,
        super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfileCleared>(_onCleared);
    on<ProfileInfoUpdated>(_onInfoUpdated);
    on<ProfileAddressSaved>(_onAddressSaved);
    on<ProfileAddressDeleted>(_onAddressDeleted);
    on<ProfileDefaultAddressSelected>(_onDefaultAddressSelected);
  }

  final ProfileRepository _repository;

  Future<void> _onLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, message: null));
    try {
      final UserProfile profile = await _repository.loadProfile(event.session);
      if (isClosed) return;
      emit(state.copyWith(status: ProfileStatus.ready, profile: profile));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'প্রোফাইল তথ্য লোড করা যায়নি।',
        ),
      );
    }
  }

  void _onCleared(ProfileCleared event, Emitter<ProfileState> emit) {
    emit(const ProfileState());
  }

  Future<void> _onInfoUpdated(
    ProfileInfoUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final UserProfile? current = state.profile;
    if (current == null) return;
    emit(state.copyWith(status: ProfileStatus.saving, message: null));
    try {
      final UserProfile updated = await _repository.updateProfile(
        phone: current.phone,
        name: event.name,
        email: event.email,
        avatarEmoji: event.avatarEmoji,
        defaultZone: event.defaultZone,
        smsNotifications: event.smsNotifications,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          profile: updated,
          message: 'প্রোফাইল আপডেট হয়েছে',
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'প্রোফাইল সেভ করা যায়নি।',
        ),
      );
    }
  }

  Future<void> _onAddressSaved(
    ProfileAddressSaved event,
    Emitter<ProfileState> emit,
  ) async {
    final UserProfile? current = state.profile;
    if (current == null) return;
    emit(state.copyWith(status: ProfileStatus.saving, message: null));
    try {
      final UserProfile updated = await _repository.saveAddress(
        current.phone,
        event.address,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          profile: updated,
          message: 'ঠিকানা সংরক্ষিত হয়েছে',
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'ঠিকানা সেভ করা যায়নি।',
        ),
      );
    }
  }

  Future<void> _onAddressDeleted(
    ProfileAddressDeleted event,
    Emitter<ProfileState> emit,
  ) async {
    final UserProfile? current = state.profile;
    if (current == null) return;
    final UserProfile updated = await _repository.deleteAddress(
      current.phone,
      event.addressId,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        status: ProfileStatus.ready,
        profile: updated,
        message: 'ঠিকানা মুছে ফেলা হয়েছে',
      ),
    );
  }

  Future<void> _onDefaultAddressSelected(
    ProfileDefaultAddressSelected event,
    Emitter<ProfileState> emit,
  ) async {
    final UserProfile? current = state.profile;
    if (current == null) return;
    final UserProfile updated = await _repository.setDefaultAddress(
      current.phone,
      event.addressId,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        status: ProfileStatus.ready,
        profile: updated,
        message: 'ডিফল্ট ঠিকানা পরিবর্তন হয়েছে',
      ),
    );
  }
}
