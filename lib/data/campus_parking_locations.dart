import 'dart:math' as math;

import '../models/parking_lot.dart';
import '../models/parking_permit.dart';

/// Verified parking entries from LSU's public campus map on November 3, 2026.
/// https://map.concept3d.com/?id=743#!ce/9488
/// The map supplies names, categories, and coordinates, not live availability.
class CampusParkingLocation {
  const CampusParkingLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.permit,
    required this.sourceLocationId,
  });

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final ParkingPermit permit;
  final int sourceLocationId;

  String get address => '$category parking · LSU campus';
  String get priceLabel =>
      permit == ParkingPermit.visitor ? 'Pay to park' : 'Permit required';

  // Approximate straight-line miles to the Student Union (LSU location 500347).
  double get distanceMiles {
    const radians = math.pi / 180;
    final dLat = (latitude - 30.412746) * radians;
    final dLon = (longitude + 91.1772) * radians;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(30.412746 * radians) *
            math.cos(latitude * radians) *
            math.pow(math.sin(dLon / 2), 2);
    return 3958.8 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  ParkingLot toParkingLot() => ParkingLot(
    id: id,
    name: name,
    address: address,
    distanceMiles: distanceMiles,
    distanceReference: 'Union',
    priceLabel: priceLabel,
    spacesAvailable: null,
    isAccessible: null,
    permitTypes: {permit},
  );

  Map<String, dynamic> toDetails() => {
    'lotId': id,
    'description': '$name is listed by LSU as $category parking.',
    'eventRestrictions':
        'Check posted signs and LSU event notices before parking.',
    'amenities': <String>[],
    'latitude': latitude,
    'longitude': longitude,
  };
}

const campusParkingLocations = <CampusParkingLocation>[
  CampusParkingLocation(
    id: "welcome-center",
    name: "Visitor Parking (Welcome Center)",
    category: "Visitor",
    latitude: 30.416122,
    longitude: -91.176949,
    permit: ParkingPermit.visitor,
    sourceLocationId: 344811,
  ),
  CampusParkingLocation(
    id: "south-stadium-visitor",
    name: "South Stadium Visitor Parking",
    category: "Visitor",
    latitude: 30.410709,
    longitude: -91.18483,
    permit: ParkingPermit.visitor,
    sourceLocationId: 344813,
  ),
  CampusParkingLocation(
    id: "thomas-boyd-visitor",
    name: "Thomas Boyd Visitor Parking Lot (Tower Drive North \"B\")",
    category: "Visitor",
    latitude: 30.415457,
    longitude: -91.178558,
    permit: ParkingPermit.visitor,
    sourceLocationId: 344814,
  ),
  CampusParkingLocation(
    id: "touchdown-village-visitor",
    name: "Touchdown Village Visitor Parking",
    category: "Visitor",
    latitude: 30.406424,
    longitude: -91.179893,
    permit: ParkingPermit.visitor,
    sourceLocationId: 355166,
  ),
  CampusParkingLocation(
    id: "parker-coliseum-visitor",
    name: "Parker Coliseum Visitor Parking",
    category: "Visitor",
    latitude: 30.408609,
    longitude: -91.175301,
    permit: ParkingPermit.visitor,
    sourceLocationId: 355167,
  ),
  CampusParkingLocation(
    id: "south-quad-west-403",
    name: "South Quad West Lot (403)",
    category: "Commuter (Zone 1)",
    latitude: 30.407219,
    longitude: -91.184097,
    permit: ParkingPermit.commuter,
    sourceLocationId: 359712,
  ),
  CampusParkingLocation(
    id: "skip-bertman-east-404",
    name: "Skip Bertman Drive East Lot (404)",
    category: "Commuter (Zone 1)",
    latitude: 30.410667,
    longitude: -91.187241,
    permit: ParkingPermit.commuter,
    sourceLocationId: 359713,
  ),
  CampusParkingLocation(
    id: "bernie-moore-104",
    name: "Bernie Moore Lot (104)",
    category: "Commuter (Zone 1)",
    latitude: 30.414856,
    longitude: -91.186844,
    permit: ParkingPermit.commuter,
    sourceLocationId: 359721,
  ),
  CampusParkingLocation(
    id: "natatorium-105",
    name: "Natatorium Lot (105)",
    category: "Commuter (Zone 1)",
    latitude: 30.41674,
    longitude: -91.186287,
    permit: ParkingPermit.commuter,
    sourceLocationId: 359723,
  ),
  CampusParkingLocation(
    id: "south-law",
    name: "South Law Lot",
    category: "Law (Zone 4)",
    latitude: 30.414021,
    longitude: -91.174149,
    permit: ParkingPermit.lawSchool,
    sourceLocationId: 352663,
  ),
  CampusParkingLocation(
    id: "fraternity-lane-east-500b",
    name: "Fraternity Lane East (Lot 500b)",
    category: "Greek Residential (Zone 2)",
    latitude: 30.416323,
    longitude: -91.173615,
    permit: ParkingPermit.greekResident,
    sourceLocationId: 352538,
  ),
  CampusParkingLocation(
    id: "greek-row-north",
    name: "Greek Row North Lot",
    category: "Greek Residential (Zone 2)",
    latitude: 30.412107,
    longitude: -91.168114,
    permit: ParkingPermit.greekResident,
    sourceLocationId: 352642,
  ),
  CampusParkingLocation(
    id: "park-geaux-tiger-park-east",
    name: "Park & Geaux Lot (Tiger Park East)",
    category: "Park & Geaux",
    latitude: 30.411627,
    longitude: -91.19236,
    permit: ParkingPermit.parkAndGeaux,
    sourceLocationId: 1077259,
  ),
  CampusParkingLocation(
    id: "skip-bertman-west-412",
    name: "Skip Bertman West (Lot 412)",
    category: "Park & Geaux",
    latitude: 30.411648452426064,
    longitude: -91.19507100384456,
    permit: ParkingPermit.parkAndGeaux,
    sourceLocationId: 1077260,
  ),
  CampusParkingLocation(
    id: "urec-north",
    name: "UREC North Lot",
    category: "Park & Geaux",
    latitude: 30.412642,
    longitude: -91.169716,
    permit: ParkingPermit.parkAndGeaux,
    sourceLocationId: 1077355,
  ),
];
