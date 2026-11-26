import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bd_phone.dart';
import 'delivery_address.dart';

/// Complete customer profile persisted across sessions.
class UserProfile extends Equatable {
  const UserProfile({
    required this.phone,
    this.name = '',
    this.email = '',
    this.avatarEmoji = '😋',
    this.defaultZone = AppConstants.defaultZone,
    this.smsNotifications = true,
    this.savedAddresses = const <DeliveryAddress>[],
  });

  final String phone;
  final String name;
  final String email;
  final String avatarEmoji;
  final String defaultZone;
  final bool smsNotifications;
  final List<DeliveryAddress> savedAddresses;

  String get displayName =>
      name.trim().isNotEmpty ? name.trim() : BdPhone.pretty(phone);

  DeliveryAddress? get defaultAddress {
    for (final DeliveryAddress address in savedAddresses) {
      if (address.isDefault) return address;
    }
    return savedAddresses.isEmpty ? null : savedAddresses.first;
  }

  UserProfile copyWith({
    String? phone,
    String? name,
    String? email,
    String? avatarEmoji,
    String? defaultZone,
    bool? smsNotifications,
    List<DeliveryAddress>? savedAddresses,
  }) {
    return UserProfile(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      defaultZone: defaultZone ?? this.defaultZone,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawAddresses =
        (json['saved_addresses'] as List<dynamic>?) ?? <dynamic>[];
    return UserProfile(
      phone: (json['phone'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      avatarEmoji: (json['avatar_emoji'] as String?) ?? '😋',
      defaultZone:
          (json['default_zone'] as String?) ?? AppConstants.defaultZone,
      smsNotifications: (json['sms_notifications'] as bool?) ?? true,
      savedAddresses: rawAddresses
          .map(
            (dynamic e) => DeliveryAddress.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phone': phone,
        'name': name,
        'email': email,
        'avatar_emoji': avatarEmoji,
        'default_zone': defaultZone,
        'sms_notifications': smsNotifications,
        'saved_addresses':
            savedAddresses.map((DeliveryAddress a) => a.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[
        phone,
        name,
        email,
        avatarEmoji,
        defaultZone,
        smsNotifications,
        savedAddresses,
      ];
}
