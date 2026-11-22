import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import 'campus_parking_locations.dart';

final sampleParkingLots = <ParkingLot>[
  ParkingLot(
    id: 'union-square-garage',
    extraTags: {ParkingTag.garage},
    name: 'Union Square Garage',
    address: '310 LSU Student Union',
    distanceMiles: 0.2,
    priceLabel: r'$1.50/hour weekdays, 7 AM–8 PM',
    spacesAvailable: null,
    isAccessible: true,
    permitTypes: {
      ParkingPermit.unionSquareGarage,
      ParkingPermit.employeeGarageC,
      ParkingPermit.visitor,
    },
  ),
  ParkingLot(
    id: 'west-stadium-lot',
    name: 'West Stadium Lot',
    address: 'North Stadium Road',
    distanceMiles: 0.4,
    priceLabel: r'$1.50/hour weekdays, 7 AM–8 PM',
    spacesAvailable: null,
    isAccessible: true,
    permitTypes: {ParkingPermit.visitor, ParkingPermit.event},
  ),
  ParkingLot(
    id: 'nicholson-gateway',
    extraTags: {ParkingTag.garage},
    name: 'Nicholson Gateway',
    address: 'Nicholson Drive at Skip Bertman Drive',
    distanceMiles: 0.8,
    priceLabel: 'Free after 5 PM',
    spacesAvailable: null,
    isAccessible: false,
    permitTypes: {ParkingPermit.nicholsonGatewayResident},
  ),
  ...campusParkingLocations.map((location) => location.toParkingLot()),
];
