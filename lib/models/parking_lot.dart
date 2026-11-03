import 'parking_permit.dart';

enum PermitEligibility { notConfigured, eligible, ineligible }

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

  bool get isAvailable => (spacesAvailable ?? 0) > 0;
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
