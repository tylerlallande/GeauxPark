import 'parking_permit.dart';
import 'parking_availability.dart';

enum PermitEligibility { notConfigured, eligible, ineligible }

enum ParkingTag {
  visitor('Visitor'),
  commuter('Commuter'),
  residential('Residential'),
  greek('Greek housing'),
  law('Law'),
  parkAndGeaux('Park & Geaux'),
  garage('Garage'),
  event('Event');

  const ParkingTag(this.label);
  final String label;
}

class ParkingLot {
  const ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceMiles,
    required this.priceLabel,
    required this.spacesAvailable,
    required this.isAccessible,
    required this.permitTypes,
    this.distanceReference,
    this.extraTags = const {},
    this.latitude,
    this.longitude,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unnamed parking lot';
    final permits = (json['permitTypes'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(parkingPermitFromId)
        .whereType<ParkingPermit>()
        .toSet();
    final extraTags = (json['extraTags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(_parkingTagFromId)
        .whereType<ParkingTag>()
        .toSet();
    if (json['gameDay'] == true) extraTags.add(ParkingTag.event);
    if (name.toLowerCase().contains('garage')) {
      extraTags.add(ParkingTag.garage);
    }
    return ParkingLot(
      id: json['id'] as String,
      name: name,
      address: json['address'] as String? ?? 'LSU campus',
      distanceMiles: (json['distanceMiles'] as num?)?.toDouble() ?? 0,
      priceLabel: json['priceLabel'] as String? ?? 'Check posted signs',
      spacesAvailable: (json['spacesAvailable'] as num?)?.toInt(),
      isAccessible: json['isAccessible'] as bool?,
      permitTypes: permits,
      distanceReference: json['distanceReference'] as String?,
      extraTags: extraTags,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String name;
  final String address;
  final double distanceMiles;
  final String priceLabel;
  final int? spacesAvailable;
  final bool? isAccessible;
  final Set<ParkingPermit> permitTypes;
  final String? distanceReference;
  final Set<ParkingTag> extraTags;
  final double? latitude;
  final double? longitude;

  Set<ParkingTag> get tags => {
    ...extraTags,
    if (permitTypes.contains(ParkingPermit.visitor)) ParkingTag.visitor,
    if (permitTypes.contains(ParkingPermit.commuter)) ParkingTag.commuter,
    if (permitTypes.any(
      {
        ParkingPermit.westCampusResident,
        ParkingPermit.eastCampusResident,
        ParkingPermit.nicholsonGatewayResident,
        ParkingPermit.greekResident,
      }.contains,
    ))
      ParkingTag.residential,
    if (permitTypes.contains(ParkingPermit.greekResident)) ParkingTag.greek,
    if (permitTypes.contains(ParkingPermit.lawSchool)) ParkingTag.law,
    if (permitTypes.contains(ParkingPermit.parkAndGeaux))
      ParkingTag.parkAndGeaux,
    if (permitTypes.contains(ParkingPermit.event)) ParkingTag.event,
  };

  bool get isAvailable => (spacesAvailable ?? 0) > 0;
  ParkingAvailabilityStatus get availabilityStatus => spacesAvailable == null
      ? ParkingAvailabilityStatus.unknown
      : spacesAvailable! > 0
      ? ParkingAvailabilityStatus.available
      : ParkingAvailabilityStatus.full;
  String get spacesLabel => spacesAvailable == null
      ? 'Availability unknown'
      : '$spacesAvailable spots';
  String get distanceLabel => distanceReference == null
      ? '${distanceMiles.toStringAsFixed(1)} mi'
      : '~${distanceMiles.toStringAsFixed(1)} mi to $distanceReference';

  PermitEligibility eligibilityFor(Set<ParkingPermit> selectedPermits) {
    if (selectedPermits.isEmpty) return PermitEligibility.notConfigured;
    return permitTypes.any(selectedPermits.contains)
        ? PermitEligibility.eligible
        : PermitEligibility.ineligible;
  }
}

ParkingTag? _parkingTagFromId(String id) {
  final normalized = id.trim().toLowerCase();
  for (final tag in ParkingTag.values) {
    if (tag.name.toLowerCase() == normalized ||
        tag.label.toLowerCase() == normalized) {
      return tag;
    }
  }
  return null;
}
