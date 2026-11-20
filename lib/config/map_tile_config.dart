import 'package:flutter/foundation.dart';

const publicOpenStreetMapTileUrl =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class MapTileConfig {
  const MapTileConfig({required this.urlTemplate, required this.isDemoSource});

  final String urlTemplate;
  final bool isDemoSource;
}

MapTileConfig? parseMapTileConfig(
  String configuredUrl, {
  required bool allowPublicDemoTiles,
  required bool isReleaseMode,
}) {
  final value = configuredUrl.trim();
  if (value.isNotEmpty) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !value.contains('{z}') ||
        !value.contains('{x}') ||
        !value.contains('{y}')) {
      return null;
    }
    return MapTileConfig(urlTemplate: value, isDemoSource: false);
  }
  if (!isReleaseMode || allowPublicDemoTiles) {
    return const MapTileConfig(
      urlTemplate: publicOpenStreetMapTileUrl,
      isDemoSource: true,
    );
  }
  return null;
}

MapTileConfig? loadMapTileConfig() {
  const configuredUrl = String.fromEnvironment('GEAUXPARK_MAP_TILE_URL');
  const allowPublicDemoTiles = bool.fromEnvironment(
    'GEAUXPARK_ALLOW_PUBLIC_OSM_DEMO_TILES',
  );
  return parseMapTileConfig(
    configuredUrl,
    allowPublicDemoTiles: allowPublicDemoTiles,
    isReleaseMode: kReleaseMode,
  );
}
