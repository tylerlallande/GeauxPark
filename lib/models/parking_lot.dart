class ParkingLot {
  const ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceMiles,
    required this.priceLabel,
    required this.spacesAvailable,
    required this.isAccessible,
  });

  final String id;
  final String name;
  final String address;
  final double distanceMiles;
  final String priceLabel;
  final int spacesAvailable;
  final bool isAccessible;
}
