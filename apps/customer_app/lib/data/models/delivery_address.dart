import 'package:equatable/equatable.dart';

/// Landmark-first delivery address (SRS FR-C04).
///
/// Birganj has no formal house numbering, so [landmark] is REQUIRED —
/// e.g. "সোনালী ব্যাংকের পেছনে", "পাইলট স্কুলের পাশে". The ops team also
/// phone-confirms every order before dispatch (business plan §5).
class DeliveryAddress extends Equatable {
  const DeliveryAddress({
    required this.recipientName,
    required this.phone,
    required this.zone,
    required this.area,
    required this.landmark,
    this.note = '',
  });

  final String recipientName;

  /// E.164, e.g. +8801712345678.
  final String phone;

  /// Selected service zone, e.g. "বীরগঞ্জ পৌরসভা".
  final String zone;

  /// Street / para / village line, e.g. "কলেজ রোড, ২য় গলি".
  final String area;

  /// The mandatory landmark line.
  final String landmark;

  /// Optional extra directions.
  final String note;

  String get oneLine => '$area — $landmark ($zone)';

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      recipientName: (json['recipient_name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      zone: (json['zone'] as String?) ?? '',
      area: (json['area'] as String?) ?? '',
      landmark: (json['landmark'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'recipient_name': recipientName,
        'phone': phone,
        'zone': zone,
        'area': area,
        'landmark': landmark,
        'note': note,
      };

  @override
  List<Object?> get props =>
      <Object?>[recipientName, phone, zone, area, landmark, note];
}
