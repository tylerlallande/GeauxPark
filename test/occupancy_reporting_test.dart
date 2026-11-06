import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/main.dart';
import 'package:geauxpark/models/parking_availability.dart';
import 'package:geauxpark/repositories/local_occupancy_report_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('occupancy reports persist with their status and timestamp', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalOccupancyReportRepository(preferences);
    final reportedAt = DateTime.utc(2026, 11, 6, 15, 30);

    await repository.saveReport(
      OccupancyReport(
        lotId: 'union-square-garage',
        status: ParkingAvailabilityStatus.veryBusy,
        reportedAt: reportedAt,
      ),
    );

    final reports = await repository.loadReports();
    expect(reports.keys, contains('union-square-garage'));
    expect(
      reports['union-square-garage']?.status,
      ParkingAvailabilityStatus.veryBusy,
    );
    expect(reports['union-square-garage']?.reportedAt, reportedAt);
  });

  test('malformed local reports do not hide valid reports', () async {
    final valid = OccupancyReport(
      lotId: 'west-stadium-lot',
      status: ParkingAvailabilityStatus.fillingUp,
      reportedAt: DateTime.utc(2026, 11, 6, 16),
    );
    SharedPreferences.setMockInitialValues({
      LocalOccupancyReportRepository.storageKey: [
        'not-json',
        jsonEncode(valid.toJson()),
      ],
    });

    final preferences = await SharedPreferences.getInstance();
    final reports = await LocalOccupancyReportRepository(preferences)
        .loadReports();

    expect(reports.length, 1);
    expect(
      reports['west-stadium-lot']?.status,
      ParkingAvailabilityStatus.fillingUp,
    );
  });

  testWidgets('users can report availability from the map', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('map-report-availability')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('report-availability-very-busy')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Union Square Garage reported as Very busy.'),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    final reports = await LocalOccupancyReportRepository(preferences)
        .loadReports();
    expect(
      reports['union-square-garage']?.status,
      ParkingAvailabilityStatus.veryBusy,
    );
  });

  testWidgets('reported occupancy controls the map marker density color', (
    tester,
  ) async {
    final report = OccupancyReport(
      lotId: 'union-square-garage',
      status: ParkingAvailabilityStatus.veryBusy,
      reportedAt: DateTime.utc(2026, 11, 6, 15, 30),
    );
    SharedPreferences.setMockInitialValues({
      LocalOccupancyReportRepository.storageKey: [jsonEncode(report.toJson())],
    });
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    final marker = tester.widget<Container>(
      find.byKey(const ValueKey('parking-marker-density-union-square-garage')),
    );
    final decoration = marker.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFE66A21));
    expect(find.textContaining('Very busy · Reported'), findsOneWidget);
  });
}
