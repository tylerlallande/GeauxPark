import '../models/parking_details.dart';

abstract interface class ParkingRepository {
  Future<ParkingDetails?> fetchParkingDetails(String lotId);
}

class ParkingRepositoryException implements Exception {
  const ParkingRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ParkingRepositoryException: $message';
}
