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

  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final x = _normalizedValue(json, 'x');
    final y = _normalizedValue(json, 'y');
    final width = _normalizedValue(json, 'width', positive: true);
    final height = _normalizedValue(json, 'height', positive: true);
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Parking space must have an identifier.');
    }
    if (x + width > 1 || y + height > 1) {
      throw const FormatException(
        'Parking space geometry must remain inside the lot boundary.',
      );
    }
    return ParkingSpace(
      id: id,
      label: json['label'] is String ? json['label'] as String : id,
      x: x,
      y: y,
      width: width,
      height: height,
      status: ParkingSpaceStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ParkingSpaceStatus.unknown,
      ),
    );
  }

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
  factory ParkingLotLayout({
    required String lotId,
    required List<ParkingSpace> spaces,
    required String sourceLabel,
    DateTime? updatedAt,
  }) => ParkingLotLayout._(
    lotId: lotId,
    spaces: spaces,
    sourceLabel: sourceLabel,
    updatedAt: updatedAt,
  );

  ParkingLotLayout._({
    required this.lotId,
    required List<ParkingSpace> spaces,
    required this.sourceLabel,
    this.updatedAt,
  }) : spaces = List<ParkingSpace>.unmodifiable(spaces);

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

double _normalizedValue(
  Map<String, dynamic> json,
  String key, {
  bool positive = false,
}) {
  final raw = json[key];
  if (raw is! num) {
    throw FormatException('Parking space $key must be numeric.');
  }
  final value = raw.toDouble();
  if (!value.isFinite || value < 0 || value > 1 || (positive && value == 0)) {
    throw FormatException('Parking space $key must be between 0 and 1.');
  }
  return value;
}
