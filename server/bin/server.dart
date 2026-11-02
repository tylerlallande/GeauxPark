import 'dart:io';

import '../lib/parking_server.dart';

Future<void> main() async {
  final dataFile = File('server/data/lots.json');
  final store = LotStore.fromJson(await dataFile.readAsString());
  await ParkingServer(store).serve(
    host: Platform.environment['GEAUXPARK_HOST'] ?? '0.0.0.0',
    port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080,
  );
}
