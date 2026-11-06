import '../models/parking_availability.dart';

abstract interface class OccupancyReportRepository {
  Future<Map<String, OccupancyReport>> loadReports();

  Future<void> saveReport(OccupancyReport report);
}
