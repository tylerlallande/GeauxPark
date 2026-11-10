import '../data/sample_parking_details.dart';
import '../data/sample_parking_lots.dart';
import '../models/parking_details.dart';
import '../models/parking_lot.dart';
import 'parking_repository.dart';

/// Temporary local implementation of [ParkingRepository].
///
/// Replace this class with an API-backed implementation when the server
/// contract is available. The screens only depend on [ParkingRepository].
class DemoParkingRepository implements ParkingRepository {
  const DemoParkingRepository();

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
}
