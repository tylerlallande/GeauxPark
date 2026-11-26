import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/main.dart';
import 'package:geauxpark/models/parking_availability.dart';
import 'package:geauxpark/models/parking_permit.dart';
import 'package:geauxpark/repositories/local_occupancy_report_repository.dart';
import 'package:geauxpark/screens/permit_preferences_screen.dart';
import 'package:geauxpark/widgets/availability_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingReportRepository extends LocalOccupancyReportRepository {
  const _FailingReportRepository(super.preferences);

  @override
  Future<Map<String, OccupancyReport>> loadReports() async {
    throw Exception('Storage unavailable');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'wrongly typed report fields are skipped without hiding valid reports',
    () async {
      final valid = OccupancyReport(
        lotId: 'west-stadium-lot',
        status: ParkingAvailabilityStatus.available,
        reportedAt: DateTime.utc(2026, 11, 25),
      );
      SharedPreferences.setMockInitialValues({
        LocalOccupancyReportRepository.storageKey: [
          for (final field in ['lotId', 'status', 'reportedAt'])
            for (final value in [
              null,
              42,
              true,
              <String>[],
              <String, String>{},
            ])
              jsonEncode({...valid.toJson(), field: value}),
          jsonEncode(valid.toJson()),
        ],
      });
      final preferences = await SharedPreferences.getInstance();
      final reports = await LocalOccupancyReportRepository(preferences)
          .loadReports();
      expect(reports.keys, [valid.lotId]);
      expect(reports[valid.lotId]?.toJson(), valid.toJson());
    },
  );

  testWidgets('malformed reports do not block saved lots or permits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'saved_parking_lot_ids': ['union-square-garage'],
      'selected_parking_permit_ids': ['visitor'],
      LocalOccupancyReportRepository.storageKey: [
        '{"lotId":"union-square-garage","status":42,"reportedAt":false}',
      ],
    });
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Union Square Garage'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    final permits = tester.widget<PermitPreferencesScreen>(
      find.byType(PermitPreferencesScreen),
    );
    expect(permits.isLoading, isFalse);
    expect(
      permits.selectedPermits.map((permit) => permit.id),
      contains('visitor'),
    );
    expect(tester.takeException(), isNull);
  });

  test('overlapping saves across repositories preserve every report', () async {
    final preferences = await SharedPreferences.getInstance();
    final reports = [
      OccupancyReport(
        lotId: 'union-square-garage',
        status: ParkingAvailabilityStatus.full,
        reportedAt: DateTime.utc(2026, 11, 23),
      ),
      OccupancyReport(
        lotId: 'west-stadium-lot',
        status: ParkingAvailabilityStatus.available,
        reportedAt: DateTime.utc(2026, 11, 23, 1),
      ),
      OccupancyReport(
        lotId: 'union-square-garage',
        status: ParkingAvailabilityStatus.fillingUp,
        reportedAt: DateTime.utc(2026, 11, 23, 2),
      ),
    ];
    await Future.wait([
      for (final report in reports)
        LocalOccupancyReportRepository(preferences).saveReport(report),
    ]);
    final loaded = await LocalOccupancyReportRepository(preferences)
        .loadReports();
    expect(
      loaded.keys,
      unorderedEquals(['union-square-garage', 'west-stadium-lot']),
    );
    for (final report in reports.skip(1)) {
      expect(loaded[report.lotId]?.toJson(), report.toJson());
    }
  });

  test('a failed queued save does not prevent the next save', () async {
    final preferences = await SharedPreferences.getInstance();
    final report = OccupancyReport(
      lotId: 'west-stadium-lot',
      status: ParkingAvailabilityStatus.available,
      reportedAt: DateTime.utc(2026, 11, 23),
    );
    final failed = _FailingReportRepository(preferences).saveReport(report);
    final succeeded = LocalOccupancyReportRepository(preferences)
        .saveReport(report);
    await expectLater(failed, throwsException);
    await succeeded;
    final loaded = await LocalOccupancyReportRepository(preferences)
        .loadReports();
    expect(loaded[report.lotId]?.toJson(), report.toJson());
  });

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

  testWidgets('availability reporting fits and scrolls on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showAvailabilityReportSheet(
                context,
                lotName: 'Small Screen Lot',
              ),
              child: const Text('Report availability'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Report availability'));
    await tester.pumpAndSettle();
    expect(find.text('How busy is Small Screen Lot?'), findsOneWidget);

    final fullOption = find.byKey(const ValueKey('report-availability-full'));
    await tester.ensureVisible(fullOption);
    await tester.pumpAndSettle();
    expect(fullOption, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
