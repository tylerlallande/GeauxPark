import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/main.dart';
import 'package:geauxpark/models/parking_details.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/repositories/parking_repository.dart';
import 'package:geauxpark/screens/parking_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('saved parking persists after restart and can be removed', (
    tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Save Union Square Garage'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Save Union Square Garage'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Unsave Union Square Garage'), findsOneWidget);
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('1 saved location'), findsOneWidget);
    expect(find.text('Union Square Garage'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Union Square Garage'), findsOneWidget);
    await tester.tap(find.byTooltip('Unsave Union Square Garage'));
    await tester.pumpAndSettle();
    expect(find.text('No saved parking yet'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('saved_parking_lot_ids'), isEmpty);
    await tester.tap(find.text('Find parking'));
    await tester.pumpAndSettle();
    expect(find.text('Find your parking'), findsOneWidget);
  });

  testWidgets('home screen presents organized parking discovery sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());

    expect(find.text('GeauxPark'), findsOneWidget);
    expect(find.text('Find your parking'), findsOneWidget);
    expect(find.text('Quick filters'), findsOneWidget);
    expect(find.text('Game-day parking'), findsOneWidget);
    expect(find.text('Parking near LSU'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Union Square Garage'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Union Square Garage'), findsOneWidget);
  });

  testWidgets('bottom navigation tabs are labeled and selectable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(find.text('Parking map'), findsOneWidget);
  });

  testWidgets('parking search filters the visible results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());

    await tester.enterText(find.byType(SearchBar), 'Nicholson');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Nicholson Gateway'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Nicholson Gateway'), findsOneWidget);
    expect(find.text('Union Square Garage'), findsNothing);
  });

  testWidgets('parking card opens repository-backed details', (tester) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Union Square Garage'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Union Square Garage'));
    await tester.pumpAndSettle();

    expect(find.text('Parking details'), findsOneWidget);
    expect(find.text('About this location'), findsOneWidget);
    expect(find.text('Hours'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Covered parking'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Covered parking'), findsOneWidget);
  });

  testWidgets('details skeleton handles unavailable server data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParkingDetailsScreen(
          lot: _testLot,
          repository: const _FakeParkingRepository(result: null),
          initiallySaved: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Information not provided yet.'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('when a parking data provider is connected'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('when a parking data provider is connected'),
      findsOneWidget,
    );
    expect(find.text('Directions unavailable'), findsOneWidget);
  });

  testWidgets('details skeleton presents retry state for server errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParkingDetailsScreen(
          lot: _testLot,
          repository: const _FakeParkingRepository(shouldThrow: true),
          initiallySaved: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load Test Garage'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

const _testLot = ParkingLot(
  id: 'test-garage',
  name: 'Test Garage',
  address: '100 Test Street',
  distanceMiles: 1,
  priceLabel: 'Price unavailable',
  spacesAvailable: 0,
  isAccessible: false,
);

class _FakeParkingRepository implements ParkingRepository {
  const _FakeParkingRepository({this.result, this.shouldThrow = false});

  final ParkingDetails? result;
  final bool shouldThrow;

  @override
  Future<ParkingDetails?> fetchParkingDetails(String lotId) async {
    if (shouldThrow) {
      throw const ParkingRepositoryException('Test failure');
    }
    return result;
  }
}
