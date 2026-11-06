import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/main.dart';
import 'package:geauxpark/models/parking_details.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/models/parking_permit.dart';
import 'package:geauxpark/repositories/parking_repository.dart';
import 'package:geauxpark/screens/parking_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder verticalScrollable() => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('official map lots can be searched, saved, and opened', (
    tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Bernie Moore');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Save Bernie Moore Lot (104)'),
      250,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('FULL'), findsNothing);
    await tester.tap(find.byTooltip('Save Bernie Moore Lot (104)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Bernie Moore Lot (104)'), findsOneWidget);
    await tester.tap(find.text('Bernie Moore Lot (104)'));
    await tester.pumpAndSettle();
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Currently full'), findsNothing);
    await tester.scrollUntilVisible(
      find.text(
        'Bernie Moore Lot (104) is listed by LSU as Commuter (Zone 1) parking.',
      ),
      200,
      scrollable: verticalScrollable().first,
    );
    expect(
      find.text(
        'Bernie Moore Lot (104) is listed by LSU as Commuter (Zone 1) parking.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('saved parking persists after restart and can be removed', (
    tester,
  ) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Save Union Square Garage'),
      300,
      scrollable: verticalScrollable().first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byTooltip('Save Union Square Garage')),
      alignment: 0.3,
    );
    await tester.pumpAndSettle();
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
    final homeScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;

    expect(find.text('GeauxPark'), findsOneWidget);
    expect(find.text('Find your parking'), findsOneWidget);
    expect(find.text('Quick filters'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Game-day parking'),
      200,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('Game-day parking'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Parking near LSU'),
      200,
      scrollable: homeScroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('Parking near LSU'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Union Square Garage'),
      300,
      scrollable: homeScroll,
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

  testWidgets('horizontal swipes move between bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();

    final pages = find.byType(PageView);
    expect(pages, findsOneWidget);
    expect(find.text('Find your parking'), findsOneWidget);

    await tester.drag(pages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Parking map'), findsOneWidget);

    await tester.drag(pages, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Saved parking'), findsOneWidget);

    await tester.drag(pages, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Parking map'), findsOneWidget);
  });

  testWidgets('permit selection persists and filters eligible lots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your parking'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('permit-nicholson-gateway-resident')),
      250,
      scrollable: verticalScrollable().first,
    );
    await tester.tap(
      find.byKey(const ValueKey('permit-nicholson-gateway-resident')),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('selected_parking_permit_ids'),
      contains('nicholson-gateway-resident'),
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My permits'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Nicholson Gateway'),
      300,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Nicholson Gateway'), findsOneWidget);
    expect(find.text('Union Square Garage'), findsNothing);
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
      scrollable: verticalScrollable().first,
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
      scrollable: verticalScrollable().first,
    );

    await tester.tap(find.text('Union Square Garage'));
    await tester.pumpAndSettle();

    expect(find.text('Parking details'), findsOneWidget);
    expect(find.text('About this location'), findsOneWidget);
    expect(find.text('Hours'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Covered parking'),
      300,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Covered parking'), findsOneWidget);
  });

  testWidgets('game-day banner opens the game-day plan', (tester) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Game-day parking'),
      200,
      scrollable: verticalScrollable().first,
    );
    await tester.tap(find.text('Game-day parking'));
    await tester.pumpAndSettle();

    expect(find.text('Game day'), findsOneWidget);
    expect(find.text('Saturday home game'), findsOneWidget);
    expect(find.text('Parking status'), findsOneWidget);
    expect(find.text('FILLING FAST'), findsOneWidget);
    expect(find.text('PERMIT ONLY'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Before you go'),
      300,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Game-day timeline'), findsOneWidget);
    expect(find.text('Before you go'), findsOneWidget);
  });

  testWidgets('game-day lot opens parking details', (tester) async {
    await tester.pumpWidget(const GeauxParkApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Game-day parking'),
      200,
      scrollable: verticalScrollable().first,
    );
    await tester.tap(find.text('Game-day parking'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('West Stadium Lot'));
    await tester.pumpAndSettle();

    expect(find.text('Parking details'), findsOneWidget);
    expect(find.text('West Stadium Lot'), findsOneWidget);
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

    await tester.scrollUntilVisible(
      find.text('About this location'),
      200,
      scrollable: verticalScrollable().first,
    );
    expect(find.text('Information not provided yet.'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('when a parking data provider is connected'),
      300,
      scrollable: verticalScrollable().first,
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
  permitTypes: {ParkingPermit.visitor},
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
