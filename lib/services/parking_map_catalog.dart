import 'package:latlong2/latlong.dart';

import '../data/parking_locations.dart';
import '../models/parking_lot.dart';

/// Precomputes map coordinates once per parking catalog update.
///
/// Marker rendering previously rebuilt the complete coordinates map for every
/// lot lookup. Keeping this projection immutable makes map builds linear and
/// avoids unnecessary work while users pan, zoom, or switch tabs on mobile.
class ParkingMapCatalog {
  ParkingMapCatalog(List<ParkingLot> lots)
    : lots = List<ParkingLot>.unmodifiable(lots),
      locations = Map<String, LatLng>.unmodifiable({
        for (final lot in lots) lot.id: ?_locationFor(lot),
      });

  final List<ParkingLot> lots;
  final Map<String, LatLng> locations;

  List<ParkingLot> matching(Set<ParkingTag> tags) => tags.isEmpty
      ? lots
      : lots
            .where((lot) => lot.tags.any(tags.contains))
            .toList(growable: false);

  static LatLng? _locationFor(ParkingLot lot) {
    if (lot.latitude case final latitude?) {
      if (lot.longitude case final longitude?) {
        return LatLng(latitude, longitude);
      }
    }
    final fallback = parkingLocations[lot.id];
    return fallback == null
        ? null
        : LatLng(fallback.latitude, fallback.longitude);
  }
}
