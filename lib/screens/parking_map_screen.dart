import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../data/sample_parking_lots.dart';
import '../data/parking_locations.dart';
import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import '../theme/app_theme.dart';
import '../widgets/parking_lot_tags.dart';
import '../services/directions_service.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({
    super.key,
    required this.savedLotIds,
    required this.onLotSelected,
    required this.selectedPermits,
    this.directionsService = const DirectionsService(),
  });

  final Set<String> savedLotIds;
  final ValueChanged<ParkingLot> onLotSelected;
  final Set<ParkingPermit> selectedPermits;
  final DirectionsService directionsService;

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _userLocation;
  bool _isLocating = false;
  bool _isTrackingLocation = false;
  bool _isGettingDirections = false;
  bool _isDirectionsOpen = false;

  static final _lotLocations = {
    for (final lot in sampleParkingLots)
      if (parkingLocations[lot.id] case final location?)
        lot.id: LatLng(location.latitude, location.longitude),
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
                                key: ValueKey('parking-marker-${lot.id}'),
                                point: location,
                                width: 54,
                                height: 62,
                                // Keep the pin tip on the coordinate at every
                                // zoom level and while rotating the map.
                                alignment: Alignment.topCenter,
                                rotate: true,
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
                                        ClipPath(
                                          clipper: const _PinTipClipper(),
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            color: isIneligible
                                                ? colors.onSurfaceVariant
                                                : colors.primary,
                                          ),
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
                      onPressed: _isLocating || _isGettingDirections
                          ? null
                          : _toggleLocationTracking,
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('map-get-directions'),
              onPressed:
                  _isGettingDirections || _isDirectionsOpen || _isLocating
                  ? null
                  : _getDirections,
              icon: _isGettingDirections
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.directions_rounded),
              label: Text(
                _isGettingDirections
                    ? 'Getting your location…'
                    : 'Get directions',
              ),
            ),
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

  Future<void> _getDirections() async {
    if (_isGettingDirections || _isDirectionsOpen || _isLocating) return;
    final lot = _selectedLot;
    final destination = _lotLocations[lot.id];
    if (destination == null) {
      _showLocationMessage('Directions are unavailable for this lot.');
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isGettingDirections = true);
    try {
      // Always request a fresh position, even if live tracking has been stopped.
      final origin = await widget.directionsService.currentLocation();
      if (!mounted) return;
      setState(() {
        _userLocation = origin;
        _isGettingDirections = false;
        _isDirectionsOpen = true;
      });
      // Choose a mode after location is ready so the browser launch happens
      // directly from a button tap, avoiding popup blocking after an await.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => _DirectionsSheet(
          lot: lot,
          origin: origin,
          destination: destination,
          service: widget.directionsService,
        ),
      );
    } on DirectionsException catch (error) {
      _showDirectionsError(error.message);
    } catch (_) {
      _showDirectionsError(
        'Could not get your location. Check location access and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingDirections = false;
          _isDirectionsOpen = false;
        });
      }
    }
  }

  void _showDirectionsError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Retry', onPressed: _getDirections),
      ),
    );
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
      final location = await widget.directionsService.currentLocation();
      if (!mounted) return;
      _updateMapLocation(location);
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
    } on DirectionsException catch (error) {
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
    _updateMapLocation(LatLng(position.latitude, position.longitude));
  }

  void _updateMapLocation(LatLng location) {
    if (!mounted) return;
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

class _DirectionsSheet extends StatefulWidget {
  const _DirectionsSheet({
    required this.lot,
    required this.origin,
    required this.destination,
    required this.service,
  });

  final ParkingLot lot;
  final LatLng origin;
  final LatLng destination;
  final DirectionsService service;

  @override
  State<_DirectionsSheet> createState() => _DirectionsSheetState();
}

class _DirectionsSheetState extends State<_DirectionsSheet> {
  bool _opening = false;
  String? _error;

  Future<void> _open(DirectionsMode mode) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final opened = await widget.service.openDirections(
        origin: widget.origin,
        destination: widget.destination,
        mode: mode,
      );
      if (!mounted) return;
      if (opened) {
        Navigator.of(context).pop();
      } else {
        setState(
          () => _error = 'Could not open Google Maps. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not open Google Maps. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Directions to ${widget.lot.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('From your current location · Opens Google Maps'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  key: const ValueKey('directions-driving'),
                  onPressed: _opening
                      ? null
                      : () => _open(DirectionsMode.driving),
                  icon: const Icon(Icons.directions_car_rounded),
                  label: const Text('Drive'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('directions-walking'),
                  onPressed: _opening
                      ? null
                      : () => _open(DirectionsMode.walking),
                  icon: const Icon(Icons.directions_walk_rounded),
                  label: const Text('Walk'),
                ),
              ],
            ),
            if (_opening) ...[
              const SizedBox(height: 12),
              const Text('Opening Google Maps…'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinTipClipper extends CustomClipper<Path> {
  const _PinTipClipper();

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width / 2, size.height)
    ..close();

  @override
  bool shouldReclip(_PinTipClipper oldClipper) => false;
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
                    const SizedBox(height: 6),
                    ParkingLotTags(lot: lot),
                    const SizedBox(height: 3),
                    Text(
                      '${lot.spacesLabel} · ${lot.priceLabel}',
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
