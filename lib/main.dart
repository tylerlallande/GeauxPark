import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_shell.dart';
import 'config/parking_api_config.dart';
import 'l10n/app_localizations.dart';
import 'repositories/api_parking_repository.dart';
import 'repositories/demo_parking_repository.dart';
import 'repositories/parking_repository.dart';
import 'theme/app_theme.dart';
import 'utils/app_diagnostics.dart';

void main() => runGeauxParkApp();

void runGeauxParkApp({
  AppErrorReporter errorReporter = const DeveloperLogErrorReporter(),
}) {
  configureAppErrorReporter(errorReporter);
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
      if (kReleaseMode) {
        ErrorWidget.builder = (details) => const _ReleaseErrorFallback();
      }
      runApp(const _RestartableGeauxPark());
    },
    (error, stackTrace) {
      recordAppError('Unhandled application-zone error', error, stackTrace);
    },
  );
}

class _ReleaseErrorFallback extends StatelessWidget {
  const _ReleaseErrorFallback();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48),
                const SizedBox(height: 16),
                Text(strings.appProblemTitle, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  strings.appProblemDescription,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _RestartableGeauxPark.restart(context),
                  child: Text(strings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestartableGeauxPark extends StatefulWidget {
  const _RestartableGeauxPark();

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_RestartableGeauxParkState>()?.restart();
  }

  @override
  State<_RestartableGeauxPark> createState() => _RestartableGeauxParkState();
}

class _RestartableGeauxParkState extends State<_RestartableGeauxPark> {
  var _generation = 0;

  void restart() => setState(() => _generation++);

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_generation),
      child: GeauxParkApp(parkingRepository: _createParkingRepository()),
    );
  }
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
