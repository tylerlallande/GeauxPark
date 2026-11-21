import '../models/parking_availability.dart';
import '../models/parking_lot.dart';
import '../models/parking_permit.dart';

class ParkingRecommendation {
  const ParkingRecommendation({required this.lot, required this.reasons});

  final ParkingLot lot;
  final List<String> reasons;
}

class ParkingRecommendationService {
  const ParkingRecommendationService();

  List<ParkingLot> rank({
    required Iterable<ParkingLot> lots,
    required Set<ParkingPermit> permits,
    required Map<String, OccupancyReport> reports,
  }) {
    final ranked = lots.toList(growable: false);
    if (permits.isEmpty) return ranked;
    ranked.sort(
      (left, right) => _score(
        right,
        permits,
        reports[right.id],
      ).compareTo(_score(left, permits, reports[left.id])),
    );
    return ranked;
  }

  ParkingRecommendation? best({
    required Iterable<ParkingLot> lots,
    required Set<ParkingPermit> permits,
    required Map<String, OccupancyReport> reports,
  }) {
    final ranked = rank(lots: lots, permits: permits, reports: reports);
    if (ranked.isEmpty) return null;
    final eligible = permits.isEmpty
        ? ranked
        : ranked
              .where(
                (lot) =>
                    lot.eligibilityFor(permits) == PermitEligibility.eligible,
              )
              .toList(growable: false);
    if (eligible.isEmpty) return null;
    final lot = eligible.first;
    final status = reports[lot.id]?.status ?? lot.availabilityStatus;
    return ParkingRecommendation(
      lot: lot,
      reasons: [
        if (permits.isNotEmpty) 'Works with your permit',
        status == ParkingAvailabilityStatus.available
            ? 'Availability reported'
            : 'Check availability',
        lot.distanceLabel,
      ],
    );
  }

  int _score(
    ParkingLot lot,
    Set<ParkingPermit> permits,
    OccupancyReport? report,
  ) {
    final eligibility = lot.eligibilityFor(permits);
    final permitScore = switch (eligibility) {
      PermitEligibility.eligible => 10000,
      PermitEligibility.notConfigured => 3000,
      PermitEligibility.ineligible => -10000,
    };
    final status = report?.status ?? lot.availabilityStatus;
    final availabilityScore = switch (status) {
      ParkingAvailabilityStatus.available => 2000,
      ParkingAvailabilityStatus.fillingUp => 1200,
      ParkingAvailabilityStatus.veryBusy => 400,
      ParkingAvailabilityStatus.unknown => 0,
      ParkingAvailabilityStatus.full => -3000,
    };
    final freshnessScore = report == null ? 0 : 300;
    final distancePenalty = (lot.distanceMiles * 100).round();
    return permitScore + availabilityScore + freshnessScore - distancePenalty;
  }
}
