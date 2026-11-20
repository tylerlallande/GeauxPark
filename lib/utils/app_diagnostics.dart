import 'dart:developer' as developer;

abstract interface class AppErrorReporter {
  void record(String operation, Object error, StackTrace stackTrace);
}

class DeveloperLogErrorReporter implements AppErrorReporter {
  const DeveloperLogErrorReporter();

  @override
  void record(String operation, Object error, StackTrace stackTrace) {
    developer.log(
      operation,
      name: 'GeauxPark',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}

AppErrorReporter _reporter = const DeveloperLogErrorReporter();

void configureAppErrorReporter(AppErrorReporter reporter) {
  _reporter = reporter;
}

void recordAppError(String operation, Object error, StackTrace stackTrace) {
  _reporter.record(operation, error, stackTrace);
}
