import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/parking_availability.dart';
import 'occupancy_report_repository.dart';

class LocalOccupancyReportRepository implements OccupancyReportRepository {
  const LocalOccupancyReportRepository(this.preferences);

  final SharedPreferences preferences;

  static const storageKey = 'parking_occupancy_reports_v1';
  // AppShell creates a repository per save, so the queue must be shared.
  static Future<void>? _pendingWrite;

  @override
  Future<Map<String, OccupancyReport>> loadReports() async {
    final encoded = preferences.getStringList(storageKey) ?? const [];
    final reports = <String, OccupancyReport>{};
    for (final item in encoded) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map) continue;
        final report = OccupancyReport.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        if (report != null) reports[report.lotId] = report;
      } on FormatException {
        // Ignore one malformed local entry instead of losing valid reports.
      }
    }
    return reports;
  }

  @override
  Future<void> saveReport(OccupancyReport report) {
    final pending = _pendingWrite;
    final write = pending == null
        ? _saveReport(report)
        : pending.then((_) => _saveReport(report));
    // Return the original failure to the caller while keeping later saves alive.
    late final Future<void> tail;
    void releaseQueue() {
      if (identical(_pendingWrite, tail)) _pendingWrite = null;
    }
    tail = write.then<void>(
      (_) => releaseQueue(),
      onError: (Object error, StackTrace stackTrace) => releaseQueue(),
    );
    _pendingWrite = tail;
    return write;
  }

  Future<void> _saveReport(OccupancyReport report) async {
    final reports = await loadReports();
    reports[report.lotId] = report;
    final encoded =
        reports.values
            .map((item) => jsonEncode(item.toJson()))
            .toList(growable: false)
          ..sort();
    final saved = await preferences.setStringList(storageKey, encoded);
    if (!saved) throw Exception('Could not save occupancy report');
  }
}
