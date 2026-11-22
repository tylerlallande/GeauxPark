import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/models/parking_details.dart';
import 'package:geauxpark/models/parking_lot.dart';
import 'package:geauxpark/models/parking_permit.dart';
import 'package:geauxpark/repositories/api_parking_repository.dart';
import 'package:geauxpark/repositories/parking_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads the parking catalog, prices, permits, and coordinates', () async {
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('http://localhost:8080'),
      fallback: const _FallbackRepository(),
      client: MockClient((request) async {
        expect(request.url.path, '/lots');
        return http.Response(
          '''{"lots":[{"id":"union-square-garage","name":"Union Square Garage","address":"LSU","distanceMiles":0.2,"priceLabel":"Permit required","spacesAvailable":42,"isAccessible":true,"permitTypes":["visitor"],"latitude":30.4,"longitude":-91.1}]}''',
          200,
        );
      }),
    );

    final lots = await repository.fetchParkingLots();

    expect(lots, hasLength(1));
    expect(lots.single.priceLabel, 'Permit required');
    expect(lots.single.permitTypes.single.id, 'visitor');
    expect(lots.single.latitude, 30.4);
    expect(lots.single.tags, contains(ParkingTag.garage));
    expect(repository.dataStatus.mode, ParkingDataMode.live);
  });

  test('loads and normalizes parking details from the server', () async {
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('http://localhost:8080'),
      fallback: const _FallbackRepository(),
      client: MockClient((request) async {
        expect(request.url.path, '/parking-lots/union-square-garage');
        return http.Response(
          '''{"id":"union-square-garage","description":"From API","latitude":30.4,"longitude":-91.1}''',
          200,
        );
      }),
    );

    final details = await repository.fetchParkingDetails('union-square-garage');

    expect(details?.lotId, 'union-square-garage');
    expect(details?.description, 'From API');
    expect(details?.hasCoordinates, isTrue);
  });

  test('uses demo data when the server cannot be reached', () async {
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('http://localhost:8080'),
      fallback: const _FallbackRepository(),
      client: MockClient(
        (request) async => throw http.ClientException('offline', request.url),
      ),
    );

    final details = await repository.fetchParkingDetails('fallback-lot');

    expect(details?.description, 'Fallback data');
  });

  test('labels fallback catalog data as an offline reference', () async {
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('http://localhost:8080'),
      fallback: const _FallbackRepository(),
      client: MockClient(
        (request) async => throw http.ClientException('offline', request.url),
      ),
    );

    await repository.fetchParkingLots();

    expect(repository.dataStatus.mode, ParkingDataMode.offlineReference);
  });

  test('notifies the UI when live data falls back offline', () async {
    var requestCount = 0;
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('https://parking.example.edu'),
      fallback: const _FallbackRepository(),
      client: MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            '''{"lots":[{"id":"live","name":"Live","address":"LSU","distanceMiles":0.2,"priceLabel":"Check signs","permitTypes":["commuter"]}]}''',
            200,
          );
        }
        throw http.ClientException('offline', request.url);
      }),
    );
    final modes = <ParkingDataMode>[];
    repository.dataStatusListenable.addListener(
      () => modes.add(repository.dataStatusListenable.value.mode),
    );

    await repository.fetchParkingLots();
    await repository.fetchParkingLots();

    expect(modes, [ParkingDataMode.live, ParkingDataMode.offlineReference]);
  });

  test('loads a verified per-space layout from the server', () async {
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('https://parking.example.edu'),
      fallback: const _FallbackRepository(),
      client: MockClient((request) async {
        expect(request.url.path, '/parking-lots/south-quad-west-403/layout');
        return http.Response(
          '''{"lotId":"south-quad-west-403","sourceLabel":"LSU","spaces":[{"id":"A1","label":"A1","x":0.1,"y":0.2,"width":0.08,"height":0.18,"status":"available"}]}''',
          200,
        );
      }),
    );

    final layout = await repository.fetchParkingLotLayout(
      'south-quad-west-403',
    );

    expect(layout?.hasVerifiedSpaces, isTrue);
    expect(layout?.spaces.single.label, 'A1');
  });

  test('does not hide unexpected programming errors', () async {
    final repository = ApiParkingRepository(
      baseUri: Uri.parse('https://parking.example.edu'),
      fallback: const _FallbackRepository(),
      client: MockClient((request) async => throw StateError('unexpected')),
    );

    await expectLater(
      repository.fetchParkingLots(),
      throwsA(isA<StateError>()),
    );
  });
}

class _FallbackRepository implements ParkingRepository {
  const _FallbackRepository();

  @override
  Future<List<ParkingLot>> fetchParkingLots() async => const [];

  @override
  Future<ParkingDetails?> fetchParkingDetails(String lotId) async {
    return ParkingDetails(lotId: lotId, description: 'Fallback data');
  }
}
