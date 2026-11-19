import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/repositories/demo_parking_repository.dart';
import 'package:geauxpark/screens/parking_lot_layout_screen.dart';

void main() {
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
