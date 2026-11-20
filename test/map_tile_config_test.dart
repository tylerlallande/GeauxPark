import 'package:flutter_test/flutter_test.dart';
import 'package:geauxpark/config/map_tile_config.dart';

void main() {
  test('accepts a secure production tile template', () {
    final config = parseMapTileConfig(
      'https://tiles.example.edu/{z}/{x}/{y}.png',
      allowPublicDemoTiles: false,
      isReleaseMode: true,
    );

    expect(config?.urlTemplate, contains('tiles.example.edu'));
    expect(config?.isDemoSource, isFalse);
  });

  test('rejects insecure or incomplete tile templates', () {
    for (final value in [
      'http://tiles.example.edu/{z}/{x}/{y}.png',
      'https://tiles.example.edu/static.png',
      'ftp://tiles.example.edu/{z}/{x}/{y}.png',
    ]) {
      expect(
        parseMapTileConfig(
          value,
          allowPublicDemoTiles: false,
          isReleaseMode: true,
        ),
        isNull,
      );
    }
  });

  test('requires explicit opt-in for public demo tiles in release mode', () {
    expect(
      parseMapTileConfig('', allowPublicDemoTiles: false, isReleaseMode: true),
      isNull,
    );
    expect(
      parseMapTileConfig(
        '',
        allowPublicDemoTiles: true,
        isReleaseMode: true,
      )?.isDemoSource,
      isTrue,
    );
  });
}
