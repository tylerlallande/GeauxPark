import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/parking_details.dart';
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
    } catch (_) {
      // An offline fallback keeps the classroom demo functional if the API or
      // campus network is temporarily unavailable.
      return fallback.fetchParkingDetails(lotId);
    }
  }
}
