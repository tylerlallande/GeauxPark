import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/models/parking_permit.dart';

void main() {
  test('parking lot collections cannot be changed after construction', () {
    final permits = <ParkingPermit>{ParkingPermit.visitor};
    final tags = <ParkingTag>{ParkingTag.garage};
    final lot = ParkingLot(
      id: 'immutable-lot',
      name: 'Immutable Lot',
      address: 'LSU campus',
      distanceMiles: 0.1,
      priceLabel: 'Free',
      spacesAvailable: 10,
      isAccessible: true,
      permitTypes: permits,
      extraTags: tags,
    );

    permits.add(ParkingPermit.commuter);
    tags.add(ParkingTag.event);

    expect(lot.permitTypes, {ParkingPermit.visitor});
    expect(lot.extraTags, {ParkingTag.garage});
    expect(
      () => lot.permitTypes.add(ParkingPermit.commuter),
      throwsUnsupportedError,
    );
    expect(() => lot.extraTags.add(ParkingTag.event), throwsUnsupportedError);
  });
}
