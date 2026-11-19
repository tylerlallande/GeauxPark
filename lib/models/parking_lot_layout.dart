import 'package:flutter/foundation.dart';

enum ParkingSpaceStatus { unknown, available, occupied, unavailable }

@immutable
class ParkingSpace {
  const ParkingSpace({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.status = ParkingSpaceStatus.unknown,
  });

  factory ParkingSpace.fromJson(Map<String, dynamic> json) => ParkingSpace(
    id: json['id'] as String,
    label: json['label'] as String? ?? json['id'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    status: ParkingSpaceStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => ParkingSpaceStatus.unknown,
    ),
  );

  final String id;
  final String label;

  /// Normalized values from 0 to 1 within the verified lot boundary.
  final double x;
  final double y;
  final double width;
  final double height;
  final ParkingSpaceStatus status;
}

@immutable
class ParkingLotLayout {
  const ParkingLotLayout({
    required this.lotId,
    required this.spaces,
    required this.sourceLabel,
    this.updatedAt,
  });

  factory ParkingLotLayout.fromJson(Map<String, dynamic> json) {
    final rawSpaces = json['spaces'];
    return ParkingLotLayout(
      lotId: json['lotId'] as String? ?? json['id'] as String,
      spaces: rawSpaces is List
          ? rawSpaces
                .whereType<Map<String, dynamic>>()
                .map(ParkingSpace.fromJson)
                .toList(growable: false)
          : const [],
      sourceLabel: json['sourceLabel'] as String? ?? 'Parking data provider',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String lotId;
  final List<ParkingSpace> spaces;
  final String sourceLabel;
  final DateTime? updatedAt;

  bool get hasVerifiedSpaces => spaces.isNotEmpty;
}
