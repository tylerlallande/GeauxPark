import '../models/parking_lot.dart';
import '../models/parking_permit.dart';

const sampleParkingLots = <ParkingLot>[
  ParkingLot(
    id: 'union-square-garage',
    name: 'Union Square Garage',
    address: '310 LSU Student Union',
    distanceMiles: 0.2,
    priceLabel: r'$8 event rate',
    spacesAvailable: 42,
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
    priceLabel: r'$12 event rate',
    spacesAvailable: 18,
    isAccessible: true,
    permitTypes: {ParkingPermit.visitor, ParkingPermit.event},
  ),
  ParkingLot(
    id: 'nicholson-gateway',
    name: 'Nicholson Gateway',
    address: 'Nicholson Drive at Skip Bertman Drive',
    distanceMiles: 0.8,
    priceLabel: 'Free after 5 PM',
    spacesAvailable: 67,
    isAccessible: false,
    permitTypes: {ParkingPermit.nicholsonGatewayResident},
  ),
];
