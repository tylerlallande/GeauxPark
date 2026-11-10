import '../models/parking_details.dart';
import '../models/parking_lot.dart';

abstract interface class ParkingRepository {
  Future<List<ParkingLot>> fetchParkingLots();

  Future<ParkingDetails?> fetchParkingDetails(String lotId);
}

class ParkingRepositoryException implements Exception {
  const ParkingRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ParkingRepositoryException: $message';
}
