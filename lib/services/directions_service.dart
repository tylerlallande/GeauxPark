import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

enum DirectionsMode { driving, walking }

class DirectionsException implements Exception {
  const DirectionsException(this.message);
  final String message;
}

Uri buildDirectionsUri({
  required LatLng origin,
  required LatLng destination,
  required DirectionsMode mode,
}) {
  for (final point in [origin, destination]) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      throw const DirectionsException(
        'Directions are unavailable for this location.',
      );
    }
  }
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': '${origin.latitude},${origin.longitude}',
    'destination': '${destination.latitude},${destination.longitude}',
    'travelmode': mode.name,
  });
}

class DirectionsService {
  const DirectionsService();

  Future<LatLng> currentLocation() async {
    // On web, getCurrentPosition triggers the browser's permission prompt.
    if (!kIsWeb) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const DirectionsException(
          'Turn on location services and try again.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const DirectionsException(
          'Allow location access for GeauxPark in your device settings.',
        );
      }
      if (permission == LocationPermission.denied) {
        throw const DirectionsException(
          'Location permission was denied. Allow access and try again.',
        );
      }
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw const DirectionsException(
        'Getting your location timed out. Please try again.',
      );
    } on PermissionDeniedException {
      throw const DirectionsException(
        'Allow location access for GeauxPark and try again.',
      );
    } on LocationServiceDisabledException {
      throw const DirectionsException(
        'Turn on location services and try again.',
      );
    }
  }

  Future<bool> openDirections({
    required LatLng origin,
    required LatLng destination,
    required DirectionsMode mode,
  }) => launchUrl(
    buildDirectionsUri(origin: origin, destination: destination, mode: mode),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}
