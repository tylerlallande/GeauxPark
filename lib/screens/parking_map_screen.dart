import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/sample_parking_lots.dart';
import '../models/parking_lot.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({
    super.key,
    required this.savedLotIds,
    required this.onLotSelected,
  });

  final Set<String> savedLotIds;
  final ValueChanged<ParkingLot> onLotSelected;

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  final MapController _mapController = MapController();

  // Approximate campus positions for the demo lots, centered around LSU.
  static const _lotLocations = <String, LatLng>{
    'union-square-garage': LatLng(30.41355, -91.18015),
    'west-stadium-lot': LatLng(30.41165, -91.18820),
    'nicholson-gateway': LatLng(30.40985, -91.17545),
  };

  ParkingLot _selectedLot = sampleParkingLots.first;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parking map', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Explore parking near LSU',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(30.4120, -91.1812),
                  initialZoom: 15.2,
                  minZoom: 12,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geauxpark.app',
                  ),
                  MarkerLayer(
                    markers: sampleParkingLots
                        .map((lot) {
                          final location = _lotLocations[lot.id];
                          if (location == null) return null;
                          final isSelected = lot.id == _selectedLot.id;
                          return Marker(
                            point: location,
                            width: 54,
                            height: 62,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedLot = lot),
                              child: Column(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colors.surface
                                            : colors.primary,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.local_parking_rounded,
                                      color: isSelected
                                          ? colors.onPrimary
                                          : colors.primary,
                                      size: 25,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: colors.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .whereType<Marker>()
                        .toList(),
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _MapZoomControls(
                      onZoomIn: () => _changeZoom(1),
                      onZoomOut: () => _changeZoom(-1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _SelectedLotCard(
            lot: _selectedLot,
            isSaved: widget.savedLotIds.contains(_selectedLot.id),
            onTap: () => widget.onLotSelected(_selectedLot),
          ),
        ],
      ),
    );
  }

  void _changeZoom(double amount) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + amount).clamp(12.0, 18.0);
    _mapController.move(camera.center, zoom);
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded),
          ),
          Container(height: 1, width: 40, color: colors.outlineVariant),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove_rounded),
          ),
        ],
      ),
    );
  }
}

class _SelectedLotCard extends StatelessWidget {
  const _SelectedLotCard({
    required this.lot,
    required this.isSaved,
    required this.onTap,
  });

  final ParkingLot lot;
  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.local_parking_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${lot.spacesAvailable} spots · ${lot.priceLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (isSaved) ...[
                Icon(Icons.bookmark_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
