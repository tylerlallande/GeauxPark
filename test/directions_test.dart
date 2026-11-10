import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geauxpark/data/parking_locations.dart';
import 'package:geauxpark/data/sample_parking_lots.dart';
import 'package:geauxpark/screens/parking_map_screen.dart';
import 'package:geauxpark/services/directions_service.dart';
import 'package:latlong2/latlong.dart' show LatLng;

class _FakeDirections extends DirectionsService {
  LatLng origin = const LatLng(30.42, -91.18);
  Object? locationError;
  bool opens = true;
  int reads = 0;
  Uri? openedUri;

  @override
  Future<LatLng> currentLocation() async {
    reads++;
    if (locationError != null) throw locationError!;
    return origin;
  }

  @override
  Future<bool> openDirections({
    required LatLng origin,
    required LatLng destination,
    required DirectionsMode mode,
  }) async {
    openedUri = buildDirectionsUri(
      origin: origin,
      destination: destination,
      mode: mode,
    );
    return opens;
  }
}

class _FakeLocationPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission granted = LocationPermission.whileInUse;
  int requests = 0;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return granted;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    settings = locationSettings;
    return Position(
      latitude: 30.42,
      longitude: -91.18,
      timestamp: DateTime(2026, 11, 4),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

Future<void> pumpMap(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test(
    'fresh location requests permission and high accuracy with a timeout',
    () async {
      final original = GeolocatorPlatform.instance;
      addTearDown(() => GeolocatorPlatform.instance = original);
      final fake = _FakeLocationPlatform();
      GeolocatorPlatform.instance = fake;
      final origin = await const DirectionsService().currentLocation();
      expect(origin, const LatLng(30.42, -91.18));
      expect(fake.requests, 1);
      expect(fake.settings?.accuracy, LocationAccuracy.high);
      expect(fake.settings?.timeLimit, const Duration(seconds: 20));
      fake.permission = LocationPermission.deniedForever;
      await expectLater(
        const DirectionsService().currentLocation(),
        throwsA(
          isA<DirectionsException>().having(
            (e) => e.message,
            'message',
            contains('device settings'),
          ),
        ),
      );
      expect(fake.requests, 1);
      fake.enabled = false;
      await expectLater(
        const DirectionsService().currentLocation(),
        throwsA(
          isA<DirectionsException>().having(
            (e) => e.message,
            'message',
            contains('Turn on location'),
          ),
        ),
      );
    },
  );

  test('route URLs use explicit coordinates and selected travel mode', () {
    for (final mode in DirectionsMode.values) {
      final uri = buildDirectionsUri(
        origin: const LatLng(30.42, -91.18),
        destination: const LatLng(30.413082, -91.174782),
        mode: mode,
      );
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['origin'], '30.42,-91.18');
      expect(uri.queryParameters['destination'], '30.413082,-91.174782');
      expect(uri.queryParameters['travelmode'], mode.name);
    }
  });

  Future<void> showMap(WidgetTester tester, _FakeDirections service) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParkingMapScreen(
            lots: sampleParkingLots,
            savedLotIds: const {},
            selectedPermits: const {},
            onLotSelected: (_) {},
            directionsService: service,
          ),
        ),
      ),
    );
    await pumpMap(tester);
  }

  testWidgets(
    'directions use the selected marker, current origin, and walking mode',
    (tester) async {
      final service = _FakeDirections();
      await showMap(tester, service);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      const markerKey = ValueKey('parking-marker-bernie-moore-104');
      final marker = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .singleWhere((marker) => marker.key == markerKey);
      map.mapController!.move(marker.point, 18);
      await pumpMap(tester);
      await tester.tap(find.byKey(markerKey));
      await pumpMap(tester);
      await tester.tap(find.byKey(const ValueKey('map-get-directions')));
      await pumpMap(tester);
      expect(find.text('Directions to Bernie Moore Lot (104)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('directions-walking')));
      await pumpMap(tester);
      final location = parkingLocations['bernie-moore-104']!;
      expect(
        service.openedUri?.queryParameters['destination'],
        '${location.latitude},${location.longitude}',
      );
      expect(service.openedUri?.queryParameters['origin'], '30.42,-91.18');
      expect(service.openedUri?.queryParameters['travelmode'], 'walking');
      // Requesting again uses a new reading rather than the cached blue dot.
      service.origin = const LatLng(30.43, -91.19);
      await tester.tap(find.byKey(const ValueKey('map-get-directions')));
      await pumpMap(tester);
      await tester.tap(find.byKey(const ValueKey('directions-driving')));
      await pumpMap(tester);
      expect(service.reads, 2);
      expect(service.openedUri?.queryParameters['origin'], '30.43,-91.19');
      expect(service.openedUri?.queryParameters['travelmode'], 'driving');
    },
  );

  testWidgets('permission failures show an error and let the user retry', (
    tester,
  ) async {
    final service = _FakeDirections()
      ..locationError = const DirectionsException(
        'Location permission was denied. Allow access and try again.',
      );
    await showMap(tester, service);
    await tester.tap(find.byKey(const ValueKey('map-get-directions')));
    await pumpMap(tester);
    expect(
      find.textContaining('Location permission was denied.'),
      findsOneWidget,
    );
    expect(service.openedUri, isNull);
    service.locationError = null;
    await tester.tap(find.text('Retry'));
    await pumpMap(tester);
    expect(find.byKey(const ValueKey('directions-driving')), findsOneWidget);
  });

  testWidgets('failed Maps launches retain the choices for retry', (
    tester,
  ) async {
    final service = _FakeDirections()..opens = false;
    await showMap(tester, service);
    await tester.tap(find.byKey(const ValueKey('map-get-directions')));
    await pumpMap(tester);
    await tester.tap(find.byKey(const ValueKey('directions-driving')));
    await pumpMap(tester);
    expect(
      find.text('Could not open Google Maps. Please try again.'),
      findsOneWidget,
    );
    service.opens = true;
    await tester.tap(find.byKey(const ValueKey('directions-driving')));
    await pumpMap(tester);
    expect(find.byKey(const ValueKey('directions-driving')), findsNothing);
  });
}
