import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'repositories/api_parking_repository.dart';
import 'repositories/demo_parking_repository.dart';
import 'repositories/parking_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(GeauxParkApp(parkingRepository: _createParkingRepository()));
}

class GeauxParkApp extends StatelessWidget {
  const GeauxParkApp({
    super.key,
    this.parkingRepository = const DemoParkingRepository(),
  });

  final ParkingRepository parkingRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeauxPark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(parkingRepository: parkingRepository),
    );
  }
}

ParkingRepository _createParkingRepository() {
  const apiUrl = String.fromEnvironment('GEAUXPARK_API_URL');
  const fallback = DemoParkingRepository();
  final baseUri = Uri.tryParse(apiUrl);
  if (baseUri == null || !baseUri.hasScheme || !baseUri.hasAuthority) {
    return fallback;
  }
  return ApiParkingRepository(baseUri: baseUri, fallback: fallback);
}
