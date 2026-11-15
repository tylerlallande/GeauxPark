import 'dart:developer' as developer;

void recordAppError(String operation, Object error, StackTrace stackTrace) {
  developer.log(
    operation,
    name: 'GeauxPark',
    error: error,
    stackTrace: stackTrace,
    level: 1000,
  );
}
