import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/models/parking_availability.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/models/parking_permit.dart';
import 'package:geauxpark/services/parking_recommendation_service.dart';

void main() {
  const service = ParkingRecommendationService();

  ParkingLot lot({
    required String id,
    required double distance,
    required Set<ParkingPermit> permits,
    int? spaces,
  }) => ParkingLot(
    id: id,
    name: id,
    address: 'LSU',
    distanceMiles: distance,
    priceLabel: 'Check signs',
    spacesAvailable: spaces,
    isAccessible: true,
    permitTypes: permits,
  );

  test('eligible available lots rank ahead of restricted and full lots', () {
    final restricted = lot(
      id: 'restricted',
      distance: 0.1,
      permits: {ParkingPermit.visitor},
      spaces: 20,
    );
    final full = lot(
      id: 'full',
      distance: 0.2,
      permits: {ParkingPermit.commuter},
      spaces: 0,
    );
    final available = lot(
      id: 'available',
      distance: 0.5,
      permits: {ParkingPermit.commuter},
      spaces: 4,
    );

    final ranked = service.rank(
      lots: [restricted, full, available],
      permits: {ParkingPermit.commuter},
      reports: const {},
    );

    expect(ranked.map((item) => item.id), [
      available.id,
      full.id,
      restricted.id,
    ]);
  });

  test('fresh user reports override bundled availability for ranking', () {
    final nearby = lot(
      id: 'nearby',
      distance: 0.1,
      permits: {ParkingPermit.commuter},
      spaces: 0,
    );
    final farther = lot(
      id: 'farther',
      distance: 0.8,
      permits: {ParkingPermit.commuter},
      spaces: 2,
    );
    final now = DateTime.utc(2026, 11, 20);

    final recommendation = service.best(
      lots: [farther, nearby],
      permits: {ParkingPermit.commuter},
      reports: {
        nearby.id: OccupancyReport(
          lotId: nearby.id,
          status: ParkingAvailabilityStatus.available,
          reportedAt: now,
        ),
      },
    );

    expect(recommendation?.lot.id, nearby.id);
    expect(recommendation?.reasons, contains('Availability reported'));
  });

  test('does not recommend a lot that rejects every selected permit', () {
    final visitor = lot(
      id: 'visitor',
      distance: 0.1,
      permits: {ParkingPermit.visitor},
      spaces: 10,
    );

    expect(
      service.best(
        lots: [visitor],
        permits: {ParkingPermit.commuter},
        reports: const {},
      ),
      isNull,
    );
  });
}
