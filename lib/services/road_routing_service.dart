import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadRouteStep {
  const RoadRouteStep({
    required this.instruction,
    required this.distanceMeters,
  });

  final String instruction;
  final double distanceMeters;
}

class RoadRoute {
  const RoadRoute({
    required this.points,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final List<RoadRouteStep> steps;
  final double distanceMeters;
  final double durationSeconds;
}

class RoadRoutingService {
  const RoadRoutingService();

  Future<RoadRoute> drivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      {'steps': 'true', 'overview': 'full', 'geometries': 'geojson'},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw const RoadRoutingException(
        'Road directions are unavailable right now.',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['code'] != 'Ok') {
      throw const RoadRoutingException(
        'No driving route was found to this lot.',
      );
    }
    final route =
        (payload['routes'] as List<dynamic>).first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final points = (geometry['coordinates'] as List<dynamic>)
        .map((coordinate) {
          final values = coordinate as List<dynamic>;
          return LatLng(
            (values[1] as num).toDouble(),
            (values[0] as num).toDouble(),
          );
        })
        .toList(growable: false);
    final legs = route['legs'] as List<dynamic>;
    final steps = <RoadRouteStep>[];
    for (final leg in legs) {
      for (final rawStep
          in (leg as Map<String, dynamic>)['steps'] as List<dynamic>) {
        final step = rawStep as Map<String, dynamic>;
        final maneuver = step['maneuver'] as Map<String, dynamic>;
        final instruction = _instruction(
          maneuver['type'] as String? ?? 'continue',
          maneuver['modifier'] as String?,
          step['name'] as String? ?? '',
        );
        steps.add(
          RoadRouteStep(
            instruction: instruction,
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }
    return RoadRoute(
      points: points,
      steps: steps,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }

  String _instruction(String type, String? modifier, String roadName) {
    final road = roadName.isEmpty ? '' : ' onto $roadName';
    final turn = switch (modifier) {
      'uturn' => 'Make a U-turn',
      'sharp right' => 'Turn sharp right',
      'right' => 'Turn right',
      'slight right' => 'Turn slightly right',
      'straight' => 'Continue straight',
      'slight left' => 'Turn slightly left',
      'left' => 'Turn left',
      'sharp left' => 'Turn sharp left',
      _ => 'Continue',
    };
    return switch (type) {
      'depart' => roadName.isEmpty ? 'Start driving' : 'Start on $roadName',
      'arrive' => 'Arrive at the parking lot',
      'roundabout' || 'rotary' => '$turn through the roundabout$road',
      'merge' => 'Merge$road',
      'ramp' => 'Take the ramp$road',
      'fork' => '$turn at the fork$road',
      'end of road' => '$turn at the end of the road$road',
      'turn' => '$turn$road',
      _ => roadName.isEmpty ? 'Continue' : 'Continue on $roadName',
    };
  }
}

class RoadRoutingException implements Exception {
  const RoadRoutingException(this.message);
  final String message;
}

String formatRouteDistance(double meters) {
  final miles = meters / 1609.344;
  if (miles < 0.1) return '${(meters * 3.28084).round()} ft';
  return '${miles.toStringAsFixed(1)} mi';
}

String formatRouteDuration(double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return remainingMinutes == 0
      ? '${hours} hr'
      : '${hours} hr $remainingMinutes min';
}
