enum ParkingAvailabilityStatus {
  unknown('unknown', 'Unknown'),
  available('available', 'Available'),
  fillingUp('filling-up', 'Filling up'),
  veryBusy('very-busy', 'Very busy'),
  full('full', 'Full');

  const ParkingAvailabilityStatus(this.id, this.label);

  final String id;
  final String label;
}

ParkingAvailabilityStatus? parkingAvailabilityStatusFromId(String? id) {
  if (id == null) return null;
  for (final status in ParkingAvailabilityStatus.values) {
    if (status.id == id) return status;
  }
  return null;
}

class OccupancyReport {
  const OccupancyReport({
    required this.lotId,
    required this.status,
    required this.reportedAt,
  });

  final String lotId;
  final ParkingAvailabilityStatus status;
  final DateTime reportedAt;

  Map<String, dynamic> toJson() => {
    'lotId': lotId,
    'status': status.id,
    'reportedAt': reportedAt.toUtc().toIso8601String(),
  };

  static OccupancyReport? fromJson(Map<String, dynamic> json) {
    final lotId = json['lotId'];
    final status = parkingAvailabilityStatusFromId(json['status'] as String?);
    final reportedAt = DateTime.tryParse(json['reportedAt'] as String? ?? '');
    if (lotId is! String ||
        lotId.isEmpty ||
        status == null ||
        reportedAt == null) {
      return null;
    }
    return OccupancyReport(
      lotId: lotId,
      status: status,
      reportedAt: reportedAt,
    );
  }
}
