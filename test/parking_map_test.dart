import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/data/parking_locations.dart';
import 'package:geauxpark/data/sample_parking_details.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/screens/parking_map_screen.dart';

void main() {
  test('every lot uses the same coordinates in details and API data', () {
    final apiLots = (jsonDecode(
      File('server/data/lots.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
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
    await tester.tap(
      find.byKey(const ValueKey('parking-marker-nicholson-gateway')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nicholson Gateway'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
