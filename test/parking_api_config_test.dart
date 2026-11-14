import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/config/parking_api_config.dart';

void main() {
  test('accepts HTTPS API URLs', () {
    expect(
      parseParkingApiBaseUri('https://parking.example.edu:8443/api'),
      Uri.parse('https://parking.example.edu:8443/api'),
    );
  });

  test('rejects unsupported schemes and malformed API URLs', () {
    for (final value in [
      '',
      'parking.example.edu',
      'ftp://parking.example.edu',
      'custom://parking.example.edu',
      'https://',
      'https://user:password@parking.example.edu',
      'https://parking.example.edu?token=secret',
      'https://parking.example.edu#fragment',
    ]) {
      expect(parseParkingApiBaseUri(value), isNull, reason: value);
    }
  });

  test('rejects HTTP without the explicit development flag', () {
    expect(parseParkingApiBaseUri('http://localhost:8080'), isNull);
    expect(parseParkingApiBaseUri('http://192.168.1.20:8080'), isNull);
  });

  test('allows explicitly enabled local development HTTP endpoints', () {
    for (final value in [
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://192.168.1.20:8080',
      'http://10.0.0.20:8080',
      'http://172.16.0.20:8080',
      'http://100.110.166.245:8080',
      'http://[::1]:8080',
    ]) {
      expect(
        parseParkingApiBaseUri(value, allowInsecureDevelopmentApi: true),
        Uri.parse(value),
        reason: value,
      );
    }
  });

  test('still rejects public HTTP when development access is enabled', () {
    expect(
      parseParkingApiBaseUri(
        'http://parking.example.edu',
        allowInsecureDevelopmentApi: true,
      ),
      isNull,
    );
    expect(
      parseParkingApiBaseUri(
        'http://8.8.8.8',
        allowInsecureDevelopmentApi: true,
      ),
      isNull,
    );
  });
}
