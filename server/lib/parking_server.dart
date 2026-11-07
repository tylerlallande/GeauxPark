import 'dart:convert';
import 'dart:io';

class ParkingLotRecord {
  const ParkingLotRecord(this.value);

  final Map<String, dynamic> value;

  String get id => value['id'] as String;

  bool get gameDay => value['gameDay'] as bool? ?? false;

  List<String> get permitTypes =>
      (value['permitTypes'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();
}

class LotStore {
  LotStore(Iterable<Map<String, dynamic>> lots)
    : _lots = lots.map(ParkingLotRecord.new).toList(growable: false);

  factory LotStore.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List) {
      throw const FormatException('Parking data must be a JSON array.');
    }
    return LotStore(
      decoded.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Each parking lot must be a JSON object.',
          );
        }
        return Map<String, dynamic>.from(item);
      }),
    );
  }

  final List<ParkingLotRecord> _lots;

  List<Map<String, dynamic>> find({bool? gameDay, String? permitType}) {
    final normalizedPermit = permitType?.trim().toLowerCase();
    return _lots
        .where((lot) {
          final matchesGameDay = gameDay == null || lot.gameDay == gameDay;
          final matchesPermit =
              normalizedPermit == null ||
              normalizedPermit.isEmpty ||
              lot.permitTypes.any(
                (permit) => permit.toLowerCase() == normalizedPermit,
              );
          return matchesGameDay && matchesPermit;
        })
        .map((lot) => lot.value)
        .toList(growable: false);
  }

  Map<String, dynamic>? findById(String id) {
    for (final lot in _lots) {
      if (lot.id == id) return lot.value;
    }
    return null;
  }
}

class ParkingServer {
  ParkingServer(this.store);

  final LotStore store;

  Future<void> serve({String host = '0.0.0.0', int port = 8080}) async {
    final server = await HttpServer.bind(host, port);
    stdout.writeln('GeauxPark API listening on http://$host:$port');
    await for (final request in server) {
      await _handle(request);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    _addCorsHeaders(request.response);
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    if (request.method != 'GET') {
      await _writeJson(request, 405, {'error': 'Method not allowed'});
      return;
    }

    final segments = request.uri.pathSegments;
    if (segments.length == 1 && segments.first == 'health') {
      await _writeJson(request, 200, {'status': 'ok'});
      return;
    }

    if (segments.length == 1 && segments.first == 'lots') {
      final gameDayValue = request.uri.queryParameters['gameDay'];
      final gameDay = gameDayValue == null
          ? null
          : switch (gameDayValue.toLowerCase()) {
              'true' => true,
              'false' => false,
              _ => null,
            };
      if (gameDayValue != null && gameDay == null) {
        await _writeJson(request, 400, {
          'error': 'gameDay must be true or false',
        });
        return;
      }
      final lots = store.find(
        gameDay: gameDay,
        permitType: request.uri.queryParameters['permitType'],
      );
      await _writeJson(request, 200, {'lots': lots});
      return;
    }

    if (segments.length == 2 &&
        (segments.first == 'lots' || segments.first == 'parking-lots')) {
      final lot = store.findById(segments[1]);
      await _writeJson(
        request,
        lot == null ? 404 : 200,
        lot ?? {'error': 'Parking lot not found'},
      );
      return;
    }

    await _writeJson(request, 404, {'error': 'Route not found'});
  }

  Future<void> _writeJson(
    HttpRequest request,
    int status,
    Map<String, dynamic> body,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }

  void _addCorsHeaders(HttpResponse response) {
    response.headers
      ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..set(HttpHeaders.accessControlAllowMethodsHeader, 'GET, OPTIONS')
      ..set(HttpHeaders.accessControlAllowHeadersHeader, 'Content-Type');
  }
}
