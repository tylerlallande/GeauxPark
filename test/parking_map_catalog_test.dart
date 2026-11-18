import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/services/parking_map_catalog.dart';

void main() {
  test('map catalog caches every known lot coordinate', () {
    final catalog = ParkingMapCatalog(sampleParkingLots);

    expect(catalog.locations.length, sampleParkingLots.length);
    expect(
      catalog.locations['union-square-garage']?.latitude,
      closeTo(30.412, 0.01),
    );
    expect(() => catalog.locations.clear(), throwsUnsupportedError);
  });

  test('map catalog filters its immutable lot snapshot', () {
    final catalog = ParkingMapCatalog(sampleParkingLots);
    final garages = catalog.matching({ParkingTag.garage});

    expect(garages, isNotEmpty);
    expect(
      garages.every((lot) => lot.tags.contains(ParkingTag.garage)),
      isTrue,
    );
    expect(catalog.matching({}), same(catalog.lots));
  });
}
