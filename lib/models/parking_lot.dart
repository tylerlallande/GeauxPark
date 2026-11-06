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
  });

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
