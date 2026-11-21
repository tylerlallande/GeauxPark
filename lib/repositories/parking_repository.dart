import '../models/parking_details.dart';
import '../models/parking_lot_layout.dart';
import '../models/parking_lot.dart';

import 'package:flutter/foundation.dart';

enum ParkingDataMode { live, offlineSample, demo }

class ParkingDataStatus {
  const ParkingDataStatus({required this.mode, required this.checkedAt});

  final ParkingDataMode mode;
  final DateTime checkedAt;

  bool get isLive => mode == ParkingDataMode.live;
}

abstract interface class ParkingRepository {
  Future<List<ParkingLot>> fetchParkingLots();

  Future<ParkingDetails?> fetchParkingDetails(String lotId);
}

/// Implemented by repositories that can explain where displayed data came
/// from. This keeps sample fallbacks from being mistaken for live occupancy.
abstract interface class ParkingDataStatusProvider {
  ParkingDataStatus get dataStatus;
}

/// Implemented by repositories whose source can change while the app is open.
abstract interface class ParkingDataStatusListenableProvider {
  ValueListenable<ParkingDataStatus> get dataStatusListenable;
}

/// Optional capability for repositories that provide verified, per-space lot
/// geometry. Keeping this separate avoids forcing every repository to invent
/// space data that it does not have.
abstract interface class ParkingLotLayoutRepository {
  Future<ParkingLotLayout?> fetchParkingLotLayout(String lotId);
}

class ParkingRepositoryException implements Exception {
  const ParkingRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ParkingRepositoryException: $message';
}
