import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/models/parking_permit.dart';
import 'package:geauxpark/screens/home_screen.dart';
import 'package:geauxpark/widgets/parking_lot_card.dart';

void main() {
  testWidgets(
    'Home puts unowned permits last and updates when permits change',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final lots = [
        sampleParkingLots[2],
        sampleParkingLots[1],
        sampleParkingLots[0],
      ];
      Future<void> render(Set<ParkingPermit> permits) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                lots: lots,
                savedLotIds: const {},
                selectedPermits: permits,
                onToggleSaved: null,
                onLotSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      List<String> visibleIds() => tester
          .widgetList<ParkingLotCard>(find.byType(ParkingLotCard))
          .map((card) => card.lot.id)
          .toList();
      await render({ParkingPermit.visitor});
      expect(visibleIds(), [
        'west-stadium-lot',
        'union-square-garage',
        'nicholson-gateway',
      ]);
      await render({ParkingPermit.nicholsonGatewayResident});
      expect(visibleIds(), [
        'nicholson-gateway',
        'west-stadium-lot',
        'union-square-garage',
      ]);
      await render({});
      expect(visibleIds(), lots.map((lot) => lot.id).toList());
      expect(lots.first.id, 'nicholson-gateway');
    },
  );

  Future<void> showHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            lots: sampleParkingLots,
            savedLotIds: const {},
            selectedPermits: const {},
            onToggleSaved: null,
            onLotSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('lot types combine with quick filters and show an empty state', (
    tester,
  ) async {
    await showHome(tester);
    await toggle(tester, 'lot-type-garage');
    expect(find.text('2 results'), findsOneWidget);
    await toggle(tester, 'quick-filter-available');
    expect(find.text('2 results'), findsOneWidget);
    await toggle(tester, 'quick-filter-accessible');
    expect(find.text('1 results'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const ValueKey('quick-filter-available')),
          )
          .selected,
      isTrue,
    );
    await toggle(tester, 'quick-filter-free');
    expect(find.text('0 results'), findsOneWidget);
    expect(find.text('No parking found'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('18 results'), findsOneWidget);
  });

  testWidgets(
    'type filters match any selected type and search clears completely',
    (tester) async {
      await showHome(tester);
      await toggle(tester, 'lot-type-visitor');
      await toggle(tester, 'lot-type-commuter');
      expect(find.text('11 results'), findsOneWidget);
      await tester.enterText(find.byType(SearchBar), 'Bernie');
      await tester.pumpAndSettle();
      expect(find.text('1 results'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).controller!.text,
        isEmpty,
      );
      expect(find.text('18 results'), findsOneWidget);
      await tester.enterText(find.byType(SearchBar), 'Garage');
      await tester.pumpAndSettle();
      // Nicholson Gateway is matched through its Garage tag.
      expect(find.text('2 results'), findsOneWidget);
    },
  );

  testWidgets(
    'unknown commuter availability is excluded and all parking resets types',
    (tester) async {
      await showHome(tester);
      await toggle(tester, 'lot-type-commuter');
      expect(find.text('4 results'), findsOneWidget);
      await toggle(tester, 'quick-filter-available');
      expect(find.text('0 results'), findsOneWidget);
      await toggle(tester, 'quick-filter-all');
      expect(find.text('18 results'), findsOneWidget);
    },
  );

  testWidgets('lot tags wrap on narrow cards', (tester) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lot = sampleParkingLots.first;
    expect(lot.tags, containsAll([ParkingTag.garage, ParkingTag.visitor]));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ParkingLotCard(
              lot: lot,
              onTap: () {},
              isSaved: false,
              onToggleSaved: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Garage'), findsOneWidget);
    expect(find.text('Visitor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
