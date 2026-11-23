import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/parking_details.dart';
import '../models/parking_lot_layout.dart';
import '../models/parking_lot.dart';
import '../utils/app_diagnostics.dart';
import 'parking_repository.dart';

/// Loads parking details from the GeauxPark server and retains verified campus
/// reference data when the live API is unavailable.
class ApiParkingRepository
    implements
        ParkingRepository,
        ParkingDataStatusProvider,
        ParkingDataStatusListenableProvider,
        ParkingLotLayoutRepository {
  ApiParkingRepository({
    required this.baseUri,
    required this.fallback,
    http.Client? client,
    this.timeout = const Duration(seconds: 3),
  }) : _client = client ?? http.Client();

  final Uri baseUri;
  final ParkingRepository fallback;
  final Duration timeout;
  final http.Client _client;
  final ValueNotifier<ParkingDataStatus> _dataStatus = ValueNotifier(
    ParkingDataStatus(
      mode: ParkingDataMode.offlineReference,
      checkedAt: DateTime.now(),
    ),
  );

  @override
  ParkingDataStatus get dataStatus => _dataStatus.value;

  @override
  ValueListenable<ParkingDataStatus> get dataStatusListenable => _dataStatus;

  void _setDataStatus(ParkingDataMode mode) {
    _dataStatus.value = ParkingDataStatus(
      mode: mode,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ParkingLot>> fetchParkingLots() async {
    try {
      final response = await _client
          .get(baseUri.resolve('/lots'))
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw ParkingRepositoryException(
          'Server returned ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['lots'] is! List) {
        throw const ParkingRepositoryException(
          'Server returned an invalid parking catalog.',
        );
      }
      final lots = (decoded['lots'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((item) => _parseApiRecord<ParkingLot>(item, ParkingLot.fromJson))
          .toList(growable: false);
      if (lots.isEmpty) {
        throw const ParkingRepositoryException(
          'Server returned an empty parking catalog.',
        );
      }
      _setDataStatus(ParkingDataMode.live);
      return lots;
    } on TimeoutException catch (error, stackTrace) {
      return _fallbackParkingLots(error, stackTrace);
    } on http.ClientException catch (error, stackTrace) {
      return _fallbackParkingLots(error, stackTrace);
    } on FormatException catch (error, stackTrace) {
      return _fallbackParkingLots(error, stackTrace);
    } on ParkingRepositoryException catch (error, stackTrace) {
      return _fallbackParkingLots(error, stackTrace);
    }
  }

  @override
  Future<ParkingLotLayout?> fetchParkingLotLayout(String lotId) async {
    try {
      final response = await _client
          .get(
            baseUri.resolve(
              '/parking-lots/${Uri.encodeComponent(lotId)}/layout',
            ),
          )
          .timeout(timeout);
      if (response.statusCode == 404) {
        return await _fallbackParkingLotLayout(lotId);
      }
      if (response.statusCode != 200) {
        throw ParkingRepositoryException(
          'Server returned ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const ParkingRepositoryException(
          'Server returned an invalid parking lot layout.',
        );
      }
      final payload = Map<String, dynamic>.from(decoded);
      payload['lotId'] ??= payload['id'] ?? lotId;
      return _parseApiRecord<ParkingLotLayout>(
        payload,
        ParkingLotLayout.fromJson,
      );
    } on TimeoutException catch (error, stackTrace) {
      recordAppError('Parking layout API unavailable', error, stackTrace);
      return _fallbackParkingLotLayout(lotId);
    } on http.ClientException catch (error, stackTrace) {
      recordAppError('Parking layout API unavailable', error, stackTrace);
      return _fallbackParkingLotLayout(lotId);
    } on FormatException catch (error, stackTrace) {
      recordAppError(
        'Parking layout API returned invalid data',
        error,
        stackTrace,
      );
      return _fallbackParkingLotLayout(lotId);
    } on ParkingRepositoryException catch (error, stackTrace) {
      recordAppError('Parking layout API unavailable', error, stackTrace);
      return _fallbackParkingLotLayout(lotId);
    }
  }

  @override
  Future<ParkingDetails?> fetchParkingDetails(String lotId) async {
    try {
      final response = await _client
          .get(baseUri.resolve('/parking-lots/${Uri.encodeComponent(lotId)}'))
          .timeout(timeout);
      if (response.statusCode == 404) {
        _setDataStatus(ParkingDataMode.offlineReference);
        return await fallback.fetchParkingDetails(lotId);
      }
      if (response.statusCode != 200) {
        throw ParkingRepositoryException(
          'Server returned ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const ParkingRepositoryException(
          'Server returned an invalid parking record.',
        );
      }
      final payload = Map<String, dynamic>.from(decoded);
      // The server stores the identifier as `id`; the app model deliberately
      // uses `lotId` so it can remain independent from the transport format.
      payload['lotId'] ??= payload['id'] ?? lotId;
      final details = _parseApiRecord<ParkingDetails>(
        payload,
        ParkingDetails.fromJson,
      );
      _setDataStatus(ParkingDataMode.live);
      return details;
    } on TimeoutException catch (error, stackTrace) {
      return _fallbackParkingDetails(lotId, error, stackTrace);
    } on http.ClientException catch (error, stackTrace) {
      return _fallbackParkingDetails(lotId, error, stackTrace);
    } on FormatException catch (error, stackTrace) {
      return _fallbackParkingDetails(lotId, error, stackTrace);
    } on ParkingRepositoryException catch (error, stackTrace) {
      return _fallbackParkingDetails(lotId, error, stackTrace);
    }
  }

  T _parseApiRecord<T>(
    Map<String, dynamic> payload,
    T Function(Map<String, dynamic>) parse,
  ) {
    try {
      return parse(payload);
    } on TypeError {
      // Model casts validate untrusted JSON field types. Translate failures
      // only at this parsing boundary; errors from requests still propagate.
      throw const FormatException('Invalid parking API field type.');
    }
  }

  Future<List<ParkingLot>> _fallbackParkingLots(
    Object error,
    StackTrace stackTrace,
  ) {
    recordAppError('Parking catalog API unavailable', error, stackTrace);
    _setDataStatus(ParkingDataMode.offlineReference);
    return fallback.fetchParkingLots();
  }

  Future<ParkingLotLayout?> _fallbackParkingLotLayout(String lotId) {
    final fallbackRepository = fallback;
    if (fallbackRepository is ParkingLotLayoutRepository) {
      return (fallbackRepository as ParkingLotLayoutRepository)
          .fetchParkingLotLayout(lotId);
    }
    return Future.value();
  }

  Future<ParkingDetails?> _fallbackParkingDetails(
    String lotId,
    Object error,
    StackTrace stackTrace,
  ) {
    recordAppError('Parking details API unavailable', error, stackTrace);
    _setDataStatus(ParkingDataMode.offlineReference);
    return fallback.fetchParkingDetails(lotId);
  }
}
