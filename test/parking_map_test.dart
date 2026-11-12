import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/parking_locations.dart';
import 'package:geauxpark/data/campus_parking_locations.dart';
import 'package:geauxpark/data/sample_parking_details.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/screens/parking_map_screen.dart';
import 'package:geauxpark/services/road_routing_service.dart';
import 'package:latlong2/latlong.dart';

class _PendingRoadRouting extends RoadRoutingService {
  final result = Completer<RoadRoute>();

  @override
  Future<RoadRoute> drivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) => result.future;
}

void main() {
  testWidgets('map markers expose labels and support keyboard selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingMapScreen(
            lots: sampleParkingLots,
            savedLotIds: const {},
            selectedPermits: const {},
            onLotSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gatewaySemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.contains('Nicholson Gateway') ?? false),
      description: 'Nicholson Gateway marker semantics',
    );
    expect(gatewaySemantics, findsOneWidget);
    final semantics = tester.widget<Semantics>(gatewaySemantics);
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.onTap, isNotNull);
    expect(semantics.properties.label, contains('Nicholson Gateway'));
    expect(semantics.properties.label, contains('Availability:'));

    final focusNode = Focus.of(tester.element(gatewaySemantics.first));
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Nicholson Gateway'), findsOneWidget);

    final unionSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.contains('Union Square Garage') ?? false),
      description: 'Union Square Garage marker semantics',
    );
    final unionFocusNode = Focus.of(tester.element(unionSemantics));
    unionFocusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Union Square Garage'), findsOneWidget);
  });

  testWidgets('map tiles render without depending on an active animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TickerMode(
          enabled: false,
          child: Scaffold(
            body: ParkingMapScreen(
              lots: sampleParkingLots,
              savedLotIds: const {},
              selectedPermits: const {},
              onLotSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(tileLayer.tileDisplay, isA<InstantaneousTileDisplay>());
  });

  for (final completeBeforeSelection in [true, false]) {
    testWidgets(
      'selecting another pin clears ${completeBeforeSelection ? 'loaded' : 'pending'} directions',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final routing = _PendingRoadRouting();
        Widget screen({String? lotId}) => MaterialApp(
          home: Scaffold(
            body: ParkingMapScreen(
              lots: sampleParkingLots,
              savedLotIds: const {},
              selectedPermits: const {},
              onLotSelected: (_) {},
              roadRoutingService: routing,
              directionsLotId: lotId,
              directionsOrigin: const LatLng(30.412, -91.181),
            ),
          ),
        );
        const route = RoadRoute(
          points: [LatLng(30.412, -91.181), LatLng(30.414, -91.179)],
          steps: [
            RoadRouteStep(instruction: 'Old lot route', distanceMeters: 200),
          ],
          distanceMeters: 200,
          durationSeconds: 60,
        );
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();
        await tester.pumpWidget(screen(lotId: 'union-square-garage'));
        await tester.pump();
        if (completeBeforeSelection) {
          routing.result.complete(route);
          await tester.pumpAndSettle();
          expect(find.byType(PolylineLayer), findsOneWidget);
          expect(find.text('Old lot route'), findsOneWidget);
        } else {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
        final gateway = layer.markers.singleWhere(
          (marker) =>
              marker.key == const ValueKey('parking-marker-nicholson-gateway'),
        );
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!
            .move(gateway.point, 18);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byKey(gateway.key!));
        await tester.pumpAndSettle();
        if (!completeBeforeSelection) {
          routing.result.complete(route);
          await tester.pumpAndSettle();
        }
        expect(find.text('Nicholson Gateway'), findsOneWidget);
        expect(find.text('Explore parking near LSU'), findsOneWidget);
        expect(find.byType(PolylineLayer), findsNothing);
        expect(find.text('Old lot route'), findsNothing);
        expect(find.text('Driving directions'), findsNothing);
      },
    );
  }

  testWidgets('map filters pins by any selected tag and clears filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingMapScreen(
            lots: sampleParkingLots,
            savedLotIds: const {},
            selectedPermits: const {},
            onLotSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final markerLayer = find.byType(MarkerLayer);
    final filterScroll = find.descendant(
      of: find.byKey(const ValueKey('map-lot-type-filters')),
      matching: find.byType(Scrollable),
    );
    for (final label in ['Commuter', 'Law']) {
      final chip = find.widgetWithText(FilterChip, label);
      await tester.scrollUntilVisible(chip, 160, scrollable: filterScroll);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    final markers = tester.widget<MarkerLayer>(markerLayer).markers;
    expect(
      markers.map((marker) => marker.key),
      containsAll([
        const ValueKey('parking-marker-bernie-moore-104'),
        const ValueKey('parking-marker-south-law'),
      ]),
    );
    expect(
      markers.any(
        (marker) =>
            marker.key == const ValueKey('parking-marker-union-square-garage'),
      ),
      isFalse,
    );
    expect(find.text('Union Square Garage'), findsNothing);
    tester.state<ScrollableState>(filterScroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    final allParking = find.widgetWithText(FilterChip, 'All parking');
    await tester.tap(allParking);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarkerLayer>(markerLayer).markers.length,
      sampleParkingLots.length,
    );
  });

  test('imported lots have unique IDs and do not invent live data', () {
    expect(campusParkingLocations.length, 15);
    expect(sampleParkingLots.length, 18);
    expect(sampleParkingLots.map((lot) => lot.id).toSet().length, 18);
    for (final location in campusParkingLocations) {
      final lot = sampleParkingLots.singleWhere((lot) => lot.id == location.id);
      expect(lot.spacesAvailable, isNull);
      expect(lot.isAccessible, isNull);
      expect(lot.isAvailable, isFalse);
      expect(lot.spacesLabel, 'Availability unknown');
      expect(lot.distanceLabel, contains('to Union'));
      expect(location.latitude, inInclusiveRange(30.40, 30.43));
      expect(location.longitude, inInclusiveRange(-91.20, -91.16));
      expect(lot.permitTypes, contains(location.permit));
      expect(sampleParkingDetails[lot.id], isNotNull);
    }
  });

  test('every lot uses the same coordinates in details and API data', () {
    final apiLots = (jsonDecode(
      File('server/data/lots.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    expect(
      apiLots.map((lot) => lot['id']).toSet(),
      sampleParkingLots.map((lot) => lot.id).toSet(),
    );
    for (final lot in sampleParkingLots) {
      final location = parkingLocations[lot.id]!;
      final details = sampleParkingDetails[lot.id]!;
      final apiLot = apiLots.singleWhere((item) => item['id'] == lot.id);
      expect(details['latitude'], location.latitude);
      expect(details['longitude'], location.longitude);
      expect(apiLot['latitude'], location.latitude);
      expect(apiLot['longitude'], location.longitude);
    }
  });

  testWidgets('pin tips stay on lot coordinates after zooming and rotating', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingMapScreen(
            lots: sampleParkingLots,
            savedLotIds: const {},
            selectedPermits: const {},
            onLotSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mapFinder = find.byType(FlutterMap);
    final controller = tester.widget<FlutterMap>(mapFinder).mapController!;

    void expectPinTipsOnCoordinates() {
      final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(layer.markers.length, sampleParkingLots.length);
      final mapOrigin = tester.getTopLeft(mapFinder);
      for (final marker in layer.markers) {
        final pin = find.byKey(marker.key!);
        final visiblePin = find
            .descendant(of: pin, matching: find.byType(GestureDetector))
            .first;
        final tip =
            tester.getBottomLeft(visiblePin) + Offset(marker.width / 2, 0);
        final expected =
            mapOrigin + controller.camera.latLngToScreenOffset(marker.point);
        expect((tip - expected).distance, lessThan(0.01));
      }
    }

    expectPinTipsOnCoordinates();
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pumpAndSettle();
    expectPinTipsOnCoordinates();
    controller.rotate(35);
    await tester.pumpAndSettle();
    expectPinTipsOnCoordinates();
    // The expanded campus catalog overlaps when zoomed out. Zoom in before
    // selecting a specific lot, as a user would when inspecting that area.
    final gateway = tester
        .widget<MarkerLayer>(find.byType(MarkerLayer))
        .markers
        .singleWhere(
          (marker) =>
              marker.key == const ValueKey('parking-marker-nicholson-gateway'),
        );
    controller.rotate(0);
    controller.move(gateway.point, 18);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('parking-marker-nicholson-gateway')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nicholson Gateway'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
