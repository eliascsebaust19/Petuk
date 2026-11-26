import 'package:equatable/equatable.dart';

/// Landmark-first delivery address (SRS FR-C04), optionally enriched with
/// saved-address metadata and GPS pin coordinates.
///
/// Birganj has no formal house numbering, so [landmark] is REQUIRED —
/// e.g. "সোনালী ব্যাংকের পেছনে", "পাইলট স্কুলের পাশে".
class DeliveryAddress extends Equatable {
  const DeliveryAddress({
    required this.recipientName,
    required this.phone,
    required this.zone,
    required this.area,
    required this.landmark,
    this.note = '',
    this.id,
    this.label = 'বাসা',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String? id;
  final String label;
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

  /// Optional GPS coordinates pinned on the map.
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get oneLine => '$area — $landmark ($zone)';

  DeliveryAddress copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phone,
    String? zone,
    String? area,
    String? landmark,
    String? note,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
    bool? isDefault,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      zone: zone ?? this.zone,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      note: note ?? this.note,
      latitude: clearCoordinates ? null : (latitude ?? this.latitude),
      longitude: clearCoordinates ? null : (longitude ?? this.longitude),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String?,
      label: (json['label'] as String?) ?? 'বাসা',
      recipientName: (json['recipient_name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      zone: (json['zone'] as String?) ?? '',
      area: (json['area'] as String?) ?? '',
      landmark: (json['landmark'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'zone': zone,
        'area': area,
        'landmark': landmark,
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        label,
        recipientName,
        phone,
        zone,
        area,
        landmark,
        note,
        latitude,
        longitude,
        isDefault,
      ];
}
