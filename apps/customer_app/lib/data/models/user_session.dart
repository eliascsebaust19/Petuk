import 'package:equatable/equatable.dart';

import '../../core/utils/bd_phone.dart';

/// The persisted login session (phone-only passwordless auth, FR-C01).
class UserSession extends Equatable {
  const UserSession({
    required this.phone,
    required this.token,
    this.name,
  });

  /// E.164, e.g. +8801712345678.
  final String phone;
  final String token;
  final String? name;

  String get displayName =>
      (name != null && name!.trim().isNotEmpty)
          ? name!.trim()
          : BdPhone.pretty(phone);

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      phone: json['phone'] as String,
      token: (json['token'] as String?) ?? '',
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phone': phone,
        'token': token,
        'name': name,
      };

  @override
  List<Object?> get props => <Object?>[phone, token, name];
}
