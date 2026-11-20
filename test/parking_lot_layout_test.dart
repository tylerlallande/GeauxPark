import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/models/parking_lot_layout.dart';
import 'package:geauxpark/repositories/demo_parking_repository.dart';
import 'package:geauxpark/screens/parking_lot_layout_screen.dart';

void main() {
  test('rejects geometry outside the normalized lot boundary', () {
    expect(
      () => ParkingSpace.fromJson({
        'id': 'A1',
        'x': 0.95,
        'y': 0.2,
        'width': 0.1,
        'height': 0.2,
      }),
      throwsFormatException,
    );
    expect(
      () => ParkingSpace.fromJson({
        'id': 'A1',
        'x': double.nan,
        'y': 0.2,
        'width': 0.1,
        'height': 0.2,
      }),
      throwsFormatException,
    );
  });

  test('lot layouts protect their immutable space collection', () {
    final source = <ParkingSpace>[
      const ParkingSpace(
        id: 'A1',
        label: 'A1',
        x: 0.1,
        y: 0.1,
        width: 0.1,
        height: 0.2,
      ),
    ];
    final layout = ParkingLotLayout(
      lotId: 'test',
      spaces: source,
      sourceLabel: 'Test',
    );

    source.clear();
    expect(layout.spaces, hasLength(1));
    expect(() => layout.spaces.clear(), throwsUnsupportedError);
  });

  testWidgets('South Quad does not fabricate unverified parking spaces', (
    tester,
  ) async {
    final lot = sampleParkingLots.firstWhere(
      (candidate) => candidate.id == 'south-quad-west-403',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ParkingLotLayoutScreen(
          lot: lot,
          repository: const DemoParkingRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verified space map coming soon'), findsOneWidget);
    expect(
      find.textContaining('verified parking-space boundaries'),
      findsOneWidget,
    );
  });
}
