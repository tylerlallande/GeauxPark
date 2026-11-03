import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/sample_parking_lots.dart';
import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import '../theme/app_theme.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({
    super.key,
    required this.savedLotIds,
    required this.onLotSelected,
    required this.selectedPermits,
  });

  final Set<String> savedLotIds;
  final ValueChanged<ParkingLot> onLotSelected;
  final Set<ParkingPermit> selectedPermits;

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _userLocation;
  bool _isLocating = false;
  bool _isTrackingLocation = false;

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.section,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parking map', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Explore parking near LSU',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (widget.selectedPermits.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _PermitLegend(),
          ],
          const SizedBox(height: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.panel),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(30.4120, -91.1812),
                  initialZoom: 15.2,
                  // Open with every lot pin fully on screen, clear of the
                  // location and zoom buttons at the top.
                  initialCameraFit: CameraFit.coordinates(
                    coordinates: _lotLocations.values.toList(),
                    padding: const EdgeInsets.fromLTRB(48, 96, 48, 56),
                    maxZoom: 16.5,
                  ),
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
                    markers:
                        sampleParkingLots
                            .map((lot) {
                              final location = _lotLocations[lot.id];
                              if (location == null) return null;
                              final isSelected = lot.id == _selectedLot.id;
                              final eligibility = lot.eligibilityFor(
                                widget.selectedPermits,
                              );
                              final isIneligible =
                                  eligibility == PermitEligibility.ineligible;
                              return Marker(
                                point: location,
                                width: 54,
                                height: 62,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedLot = lot),
                                  child: Opacity(
                                    opacity: isIneligible ? 0.42 : 1,
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
                                              color: isIneligible
                                                  ? colors.onSurfaceVariant
                                                  : isSelected
                                                  ? colors.surface
                                                  : colors.primary,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colors.shadow.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            isIneligible
                                                ? Icons.block_rounded
                                                : Icons.local_parking_rounded,
                                            color: isSelected
                                                ? colors.onPrimary
                                                : isIneligible
                                                ? colors.onSurfaceVariant
                                                : colors.primary,
                                            size: 25,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: isIneligible
                                              ? colors.onSurfaceVariant
                                              : colors.primary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                            .whereType<Marker>()
                            .toList()
                          ..addAll(
                            _userLocation == null
                                ? const []
                                : [
                                    Marker(
                                      point: _userLocation!,
                                      width: 34,
                                      height: 34,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colors.tertiary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colors.onTertiary,
                                            width: 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colors.shadow.withValues(
                                                alpha: 0.27,
                                              ),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                          ),
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
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _MyLocationButton(
                      isLoading: _isLocating,
                      isTracking: _isTrackingLocation,
                      onPressed: _isLocating ? null : _toggleLocationTracking,
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
            permitEligibility: _selectedLot.eligibilityFor(
              widget.selectedPermits,
            ),
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

  Future<void> _toggleLocationTracking() async {
    if (_isTrackingLocation) {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      if (mounted) setState(() => _isTrackingLocation = false);
      return;
    }

    setState(() => _isLocating = true);
    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw const _LocationIssue(
            'Turn on location services and try again.',
          );
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          throw const _LocationIssue('Location permission was denied.');
        }
        if (permission == LocationPermission.deniedForever) {
          throw const _LocationIssue(
            'Allow location access for GeauxPark in your device settings.',
          );
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _updateUserLocation(position);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            _updateUserLocation,
            onError: (Object error) {
              if (!mounted) return;
              setState(() => _isTrackingLocation = false);
              _showLocationMessage('Live location stopped: $error');
            },
            cancelOnError: true,
          );
      if (mounted) setState(() => _isTrackingLocation = true);
    } on _LocationIssue catch (error) {
      _showLocationMessage(error.message);
    } catch (_) {
      _showLocationMessage(
        'Could not get your location. Check your location permission and try again.',
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _updateUserLocation(Position position) {
    if (!mounted) return;
    final location = LatLng(position.latitude, position.longitude);
    setState(() => _userLocation = location);
    _mapController.move(location, _mapController.camera.zoom);
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

class _LocationIssue implements Exception {
  const _LocationIssue(this.message);

  final String message;
}

class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({
    required this.isLoading,
    required this.isTracking,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isTracking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isTracking ? colors.primary : colors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: isTracking ? 'Stop live location' : 'Use my live location',
        onPressed: onPressed,
        color: isTracking ? colors.onPrimary : colors.primary,
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isTracking ? Icons.location_searching : Icons.my_location),
      ),
    );
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
    required this.permitEligibility,
  });

  final ParkingLot lot;
  final bool isSaved;
  final VoidCallback onTap;
  final PermitEligibility permitEligibility;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
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
                    if (permitEligibility !=
                        PermitEligibility.notConfigured) ...[
                      const SizedBox(height: 4),
                      Text(
                        permitEligibility == PermitEligibility.eligible
                            ? 'Works with your permit'
                            : 'Your permit is not accepted here',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color:
                                  permitEligibility ==
                                      PermitEligibility.eligible
                                  ? colors.tertiary
                                  : colors.error,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
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

class _PermitLegend extends StatelessWidget {
  const _PermitLegend();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 16, color: colors.tertiary),
        const SizedBox(width: 4),
        const Text('Eligible'),
        const SizedBox(width: 14),
        Icon(Icons.block_rounded, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        const Text('Permit restricted'),
      ],
    );
  }
}
