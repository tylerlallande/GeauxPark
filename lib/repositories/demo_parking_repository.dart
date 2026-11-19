import '../data/sample_parking_details.dart';
import '../data/sample_parking_lots.dart';
import '../models/parking_details.dart';
import '../models/parking_lot_layout.dart';
import '../models/parking_lot.dart';
import 'parking_repository.dart';

/// Temporary local implementation of [ParkingRepository].
///
/// Replace this class with an API-backed implementation when the server
/// contract is available. The screens only depend on [ParkingRepository].
class DemoParkingRepository
    implements
        ParkingRepository,
        ParkingDataStatusProvider,
        ParkingLotLayoutRepository {
  const DemoParkingRepository();

  @override
  ParkingDataStatus get dataStatus =>
      ParkingDataStatus(mode: ParkingDataMode.demo, checkedAt: DateTime.now());

  @override
  Future<List<ParkingLot>> fetchParkingLots() async {
    return List.unmodifiable(sampleParkingLots);
  }

  @override
  Future<ParkingDetails?> fetchParkingDetails(String lotId) async {
    final payload = sampleParkingDetails[lotId];
    if (payload == null) return null;
    return ParkingDetails.fromJson(payload);
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
