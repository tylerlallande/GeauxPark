import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release can reach parking and map services', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(
      manifest,
      contains('android.permission.INTERNET'),
      reason: 'Release builds need Internet access for API, tiles, and routes.',
    );
  });

  for (final entitlement in [
    'macos/Runner/DebugProfile.entitlements',
    'macos/Runner/Release.entitlements',
  ]) {
    test('$entitlement allows outgoing network requests', () {
      final contents = File(entitlement).readAsStringSync();

      expect(contents, contains('com.apple.security.network.client'));
      expect(
        contents,
        contains('<key>com.apple.security.network.client</key>\n\t<true/>'),
      );
    });
  }

  test('map identifies requests with the application package name', () {
    final mapScreen = File('lib/screens/parking_map_screen.dart')
        .readAsStringSync();

    expect(
      mapScreen,
      contains("userAgentPackageName: 'com.geauxpark.geauxpark'"),
    );
  });
}
