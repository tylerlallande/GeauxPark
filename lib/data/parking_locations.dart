import 'campus_parking_locations.dart';

/// Parking locations verified against LSU's interactive campus map.
/// https://map.concept3d.com/?id=743
/// Union Square: location 360623; West Stadium: 359719;
/// Nicholson Gateway Garage: 759345. Verified November 3, 2026.
final parkingLocations = <String, ({double latitude, double longitude})>{
  'union-square-garage': (latitude: 30.413082, longitude: -91.174782),
  'west-stadium-lot': (latitude: 30.411709, longitude: -91.185799),
  'nicholson-gateway': (latitude: 30.413839, longitude: -91.188286),
  for (final location in campusParkingLocations)
    location.id: (latitude: location.latitude, longitude: location.longitude),
};
