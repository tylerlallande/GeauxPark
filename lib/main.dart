import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_shell.dart';
import 'config/parking_api_config.dart';
import 'l10n/app_localizations.dart';
import 'repositories/api_parking_repository.dart';
import 'repositories/demo_parking_repository.dart';
import 'repositories/parking_repository.dart';
import 'theme/app_theme.dart';
import 'utils/app_diagnostics.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        recordAppError(
          'Unhandled Flutter framework error',
          details.exception,
          details.stack ?? StackTrace.current,
        );
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        recordAppError('Unhandled asynchronous error', error, stackTrace);
        return true;
      };
      runApp(GeauxParkApp(parkingRepository: _createParkingRepository()));
    },
    (error, stackTrace) {
      recordAppError('Unhandled application-zone error', error, stackTrace);
    },
  );
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
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(parkingRepository: parkingRepository),
    );
  }
}

ParkingRepository _createParkingRepository() {
  const apiUrl = String.fromEnvironment('GEAUXPARK_API_URL');
  const allowInsecureDevelopmentApi = bool.fromEnvironment(
    'GEAUXPARK_ALLOW_INSECURE_DEVELOPMENT_API',
  );
  const fallback = DemoParkingRepository();
  final baseUri = parseParkingApiBaseUri(
    apiUrl,
    allowInsecureDevelopmentApi: allowInsecureDevelopmentApi,
  );
  if (baseUri == null) return fallback;
  return ApiParkingRepository(baseUri: baseUri, fallback: fallback);
}
