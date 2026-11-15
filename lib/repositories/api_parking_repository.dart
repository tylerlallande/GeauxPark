import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/parking_details.dart';
import '../models/parking_lot.dart';
import '../utils/app_diagnostics.dart';
import 'parking_repository.dart';

/// Loads parking details from the GeauxPark server and keeps the demo usable
/// when the API is unavailable.
class ApiParkingRepository implements ParkingRepository {
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
      if (decoded is! Map || decoded['lots'] is! List) {
        throw const ParkingRepositoryException(
          'Server returned an invalid parking catalog.',
        );
      }
      final lots = (decoded['lots'] as List<dynamic>)
          .whereType<Map>()
          .map((item) => ParkingLot.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      if (lots.isEmpty) {
        throw const ParkingRepositoryException(
          'Server returned an empty parking catalog.',
        );
      }
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
  Future<ParkingDetails?> fetchParkingDetails(String lotId) async {
    try {
      final response = await _client
          .get(baseUri.resolve('/parking-lots/${Uri.encodeComponent(lotId)}'))
          .timeout(timeout);
      if (response.statusCode == 404) {
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
      return ParkingDetails.fromJson(payload);
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

  Future<List<ParkingLot>> _fallbackParkingLots(
    Object error,
    StackTrace stackTrace,
  ) {
    recordAppError('Parking catalog API unavailable', error, stackTrace);
    return fallback.fetchParkingLots();
  }

  Future<ParkingDetails?> _fallbackParkingDetails(
    String lotId,
    Object error,
    StackTrace stackTrace,
  ) {
    recordAppError('Parking details API unavailable', error, stackTrace);
    return fallback.fetchParkingDetails(lotId);
  }
}
