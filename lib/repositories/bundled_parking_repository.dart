import '../data/sample_parking_details.dart';
import '../data/sample_parking_lots.dart';
import '../models/parking_details.dart';
import '../models/parking_lot_layout.dart';
import '../models/parking_lot.dart';
import 'parking_repository.dart';

/// Verified campus reference data bundled with the app for poor connectivity.
///
/// It never claims to provide live availability. Unknown values remain unknown
/// until the production API or a recent user report supplies them.
class BundledParkingRepository
    implements
        ParkingRepository,
        ParkingDataStatusProvider,
        ParkingLotLayoutRepository {
  const BundledParkingRepository();

  @override
  ParkingDataStatus get dataStatus => ParkingDataStatus(
    mode: ParkingDataMode.offlineReference,
    checkedAt: DateTime.now(),
  );

  @override
  Future<List<ParkingLot>> fetchParkingLots() async =>
      List.unmodifiable(sampleParkingLots);

  @override
  Future<ParkingDetails?> fetchParkingDetails(String lotId) async {
    final payload = sampleParkingDetails[lotId];
    return payload == null ? null : ParkingDetails.fromJson(payload);
  }

  @override
  Future<ParkingLotLayout?> fetchParkingLotLayout(String lotId) async {
    if (lotId != 'south-quad-west-403' &&
        lotId != 'touchdown-village-visitor') {
      return null;
    }
    return ParkingLotLayout(
      lotId: lotId,
      spaces: const [],
      sourceLabel: 'Awaiting verified LSU lot geometry',
    );
  }
}
