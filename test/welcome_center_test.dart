import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/models/parking_permit.dart';
import 'package:geauxpark/repositories/bundled_parking_repository.dart';
import 'package:geauxpark/screens/home_screen.dart';

void main() {
  const repository = BundledParkingRepository();

  test(
    'bundled Welcome Center guidance includes current visitor rules',
    () async {
      final details = await repository.fetchParkingDetails('welcome-center');
      final lot = sampleParkingLots.firstWhere(
        (item) => item.id == 'welcome-center',
      );

      expect(lot.address, 'Highland Road at Dalrymple Drive');
      expect(lot.priceLabel, r'$1.50/hour weekdays, 7 AM–8 PM');
      expect(
        details?.description,
        contains('Highland Road and Dalrymple Drive'),
      );
      expect(details?.hours, contains('7:00 AM–4:30 PM'));
      expect(details?.eventRestrictions, contains(r'$10 per day'));
      expect(details?.amenities, contains('Campus maps and directions'));
    },
  );

  testWidgets('visitor permit exposes a direct Welcome Center path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selectedLotId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            lots: sampleParkingLots,
            savedLotIds: const {},
            selectedPermits: const {ParkingPermit.visitor},
            onToggleSaved: null,
            onLotSelected: (lot) => selectedLotId = lot.id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('welcome-center-help')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('welcome-center-help')));

    expect(selectedLotId, 'welcome-center');
  });
}
