class ParkingDetails {
  const ParkingDetails({
    required this.lotId,
    this.description,
    this.hours,
    this.eventRestrictions,
    this.amenities = const [],
    this.latitude,
    this.longitude,
    this.availabilityUpdatedAt,
  });

  factory ParkingDetails.fromJson(Map<String, dynamic> json) {
    return ParkingDetails(
      lotId: json['lotId'] as String,
      description: json['description'] as String?,
      hours: json['hours'] as String?,
      eventRestrictions: json['eventRestrictions'] as String?,
      amenities: (json['amenities'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      availabilityUpdatedAt: _parseDate(json['availabilityUpdatedAt']),
    );
  }

  final String lotId;
  final String? description;
  final String? hours;
  final String? eventRestrictions;
  final List<String> amenities;
  final double? latitude;
  final double? longitude;
  final DateTime? availabilityUpdatedAt;

  bool get hasCoordinates => latitude != null && longitude != null;

  static DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
