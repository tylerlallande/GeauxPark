import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../data/parking_locations.dart';
import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import '../models/parking_availability.dart';
import '../theme/app_theme.dart';
import '../widgets/parking_lot_tags.dart';
import '../widgets/road_routing_consent.dart';
import '../widgets/availability_indicator.dart';
import '../services/directions_service.dart';
import '../services/road_routing_service.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({
    super.key,
    required this.lots,
    required this.savedLotIds,
    required this.onLotSelected,
    required this.selectedPermits,
    this.directionsLotId,
    this.directionsOrigin,
    this.directionsService = const DirectionsService(),
    this.roadRoutingService = const RoadRoutingService(),
    this.occupancyReports = const {},
    this.onReportAvailability,
  });

  final List<ParkingLot> lots;
  final Set<String> savedLotIds;
  final ValueChanged<ParkingLot> onLotSelected;
  final Set<ParkingPermit> selectedPermits;
  final String? directionsLotId;
  final LatLng? directionsOrigin;
  final DirectionsService directionsService;
  final RoadRoutingService roadRoutingService;
  final Map<String, OccupancyReport> occupancyReports;
  final Future<bool> Function(ParkingLot lot, ParkingAvailabilityStatus status)?
  onReportAvailability;

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
  bool _showRoute = false;
  RoadRoute? _roadRoute;
  String? _routeError;
  int _routeRequestId = 0;

  late ParkingLot _selectedLot;
  Set<ParkingTag> _selectedTags = {};

  void _selectLot(ParkingLot lot) {
    if (lot.id == _selectedLot.id) return;
    setState(() {
      _selectedLot = lot;
      _routeRequestId++;
      _showRoute = false;
      _roadRoute = null;
      _routeError = null;
      _isGettingDirections = false;
    });
  }

  List<ParkingLot> _matchingLots(Set<ParkingTag> tags) => widget.lots
      .where((lot) => tags.isEmpty || lot.tags.any(tags.contains))
      .toList();

  void _applyTags(Set<ParkingTag> tags) {
    final matches = _matchingLots(tags);
    setState(() {
      _selectedTags = tags;
      if (!matches.contains(_selectedLot)) {
        _showRoute = false;
        _roadRoute = null;
        _routeError = null;
        if (matches.isNotEmpty) _selectedLot = matches.first;
      }
    });
  }

  Map<String, LatLng> get _lotLocations {
    final locations = <String, LatLng>{};
    for (final lot in widget.lots) {
      final location = _locationFor(lot);
      if (location != null) locations[lot.id] = location;
    }
    return locations;
  }

  LatLng? _locationFor(ParkingLot lot) {
    if (lot.latitude != null && lot.longitude != null) {
      return LatLng(lot.latitude!, lot.longitude!);
    }
    final fallback = parkingLocations[lot.id];
    return fallback == null
        ? null
        : LatLng(fallback.latitude, fallback.longitude);
  }

  @override
  void initState() {
    super.initState();
    _selectedLot = widget.lots.first;
  }

  @override
  void didUpdateWidget(covariant ParkingMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.lots.any((lot) => lot.id == _selectedLot.id)) {
      _selectedLot = widget.lots.first;
    }
    if (widget.directionsLotId == null ||
        (widget.directionsLotId == oldWidget.directionsLotId &&
            widget.directionsOrigin == oldWidget.directionsOrigin)) {
      return;
    }
    final lotIndex = widget.lots.indexWhere(
      (lot) => lot.id == widget.directionsLotId,
    );
    if (lotIndex < 0) return;
    final lot = widget.lots[lotIndex];
    final origin = widget.directionsOrigin;
    if (origin == null) return;
    final destination = _lotLocations[lot.id];
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedLot = lot;
        if (_selectedTags.isNotEmpty && !lot.tags.any(_selectedTags.contains)) {
          _selectedTags = {};
        }
        _userLocation = origin;
        _showRoute = true;
        _roadRoute = null;
        _routeError = null;
        _isGettingDirections = true;
      });
      unawaited(_fetchRoadRoute(origin, destination));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matchingLots = _matchingLots(_selectedTags);
    final canFilter = !_isGettingDirections && !_isDirectionsOpen;

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
            _showRoute
                ? 'Directions to ${_selectedLot.name}'
                : 'Explore parking near LSU',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          const _AvailabilityLegend(),
          const SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: ListView(
              key: const ValueKey('map-lot-type-filters'),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All parking'),
                  visualDensity: VisualDensity.compact,
                  selected: _selectedTags.isEmpty,
                  onSelected: canFilter ? (_) => _applyTags({}) : null,
                ),
                const SizedBox(width: 6),
                for (final tag in ParkingTag.values) ...[
                  FilterChip(
                    label: Text(tag.label),
                    visualDensity: VisualDensity.compact,
                    selected: _selectedTags.contains(tag),
                    onSelected: canFilter
                        ? (selected) => _applyTags({
                            ..._selectedTags.where((active) => active != tag),
                            if (selected) tag,
                          })
                        : null,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          if (widget.selectedPermits.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _PermitLegend(),
          ],
          const SizedBox(height: 18),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: _showRoute ? 6 : 1,
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
                          userAgentPackageName: 'com.geauxpark.geauxpark',
                          // The tab remains mounted while inactive and its
                          // tickers are paused for smoother navigation. Avoid
                          // fade-in tiles getting stuck transparent when they
                          // finish loading before the Map tab becomes active.
                          tileDisplay: const TileDisplay.instantaneous(),
                        ),
                        if (_roadRoute != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _roadRoute!.points,
                                color: colors.primary,
                                strokeWidth: 5,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers:
                              matchingLots
                                  .map((lot) {
                                    final location = _lotLocations[lot.id];
                                    if (location == null) return null;
                                    final isSelected =
                                        lot.id == _selectedLot.id;
                                    final eligibility = lot.eligibilityFor(
                                      widget.selectedPermits,
                                    );
                                    final isIneligible =
                                        eligibility ==
                                        PermitEligibility.ineligible;
                                    final availability =
                                        widget
                                            .occupancyReports[lot.id]
                                            ?.status ??
                                        lot.availabilityStatus;
                                    final markerColor = isIneligible
                                        ? colors.onSurfaceVariant
                                        : availabilityColor(
                                            availability,
                                            colors,
                                          );
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
                                        onTap: () => _selectLot(lot),
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          opacity: isIneligible ? 0.42 : 1,
                                          child: AnimatedScale(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            curve: Curves.easeOutBack,
                                            scale: isSelected ? 1 : 0.88,
                                            child: Column(
                                              children: [
                                                Container(
                                                  key: ValueKey(
                                                    'parking-marker-density-${lot.id}',
                                                  ),
                                                  width: 46,
                                                  height: 46,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? markerColor
                                                        : markerColor
                                                              .withValues(
                                                                alpha: 0.9,
                                                              ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isIneligible
                                                          ? colors
                                                                .onSurfaceVariant
                                                          : isSelected
                                                          ? colors.primary
                                                          : colors.surface,
                                                      width: isSelected ? 3 : 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: colors.shadow
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          3,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    isIneligible
                                                        ? Icons.block_rounded
                                                        : Icons
                                                              .local_parking_rounded,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : isIneligible
                                                        ? colors
                                                              .onSurfaceVariant
                                                        : Colors.white,
                                                    size: 25,
                                                  ),
                                                ),
                                                ClipPath(
                                                  clipper:
                                                      const _PinTipClipper(),
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    color: isIneligible
                                                        ? colors
                                                              .onSurfaceVariant
                                                        : markerColor,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                                    color: colors.shadow
                                                        .withValues(
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
                if (_showRoute) ...[
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 4,
                    child: _RouteStepsPanel(
                      route: _roadRoute,
                      isLoading: _isGettingDirections,
                      error: _routeError,
                      onRetry: _getDirections,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (matchingLots.isEmpty)
            const Text('No parking lots match these tags.')
          else ...[
            _SelectedLotCard(
              lot: _selectedLot,
              isSaved: widget.savedLotIds.contains(_selectedLot.id),
              permitEligibility: _selectedLot.eligibilityFor(
                widget.selectedPermits,
              ),
              occupancyReport: widget.occupancyReports[_selectedLot.id],
              onTap: () => widget.onLotSelected(_selectedLot),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('map-report-availability'),
                onPressed: widget.onReportAvailability == null
                    ? null
                    : _reportSelectedLot,
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Report availability'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('map-get-directions'),
                onPressed:
                    _isGettingDirections || _isDirectionsOpen || _isLocating
                    ? null
                    : _openExternalDirections,
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
        ],
      ),
    );
  }

  void _changeZoom(double amount) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + amount).clamp(12.0, 18.0);
    _mapController.move(camera.center, zoom);
  }

  Future<void> _reportSelectedLot() async {
    final callback = widget.onReportAvailability;
    if (callback == null) return;
    final lot = _selectedLot;
    final current = widget.occupancyReports[lot.id];
    final status = await showAvailabilityReportSheet(
      context,
      lotName: lot.name,
      currentStatus: current?.status,
    );
    if (!mounted || status == null) return;
    await callback(lot, status);
  }

  Future<void> _openExternalDirections() async {
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
      final origin = await widget.directionsService.currentLocation();
      if (!mounted) return;
      setState(() {
        _userLocation = origin;
        _isGettingDirections = false;
        _isDirectionsOpen = true;
      });
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
      _showDirectionsError(error.message, onRetry: _openExternalDirections);
    } catch (_) {
      _showDirectionsError(
        'Could not get your location. Check location access and try again.',
        onRetry: _openExternalDirections,
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

  Future<void> _getDirections() async {
    if (_isGettingDirections || _isLocating) return;
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
      if (!await confirmRoadRoutingConsent(context) || !mounted) return;
      setState(() {
        _userLocation = origin;
        _showRoute = true;
        _roadRoute = null;
        _routeError = null;
      });
      await _fetchRoadRoute(origin, destination);
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
        });
      }
    }
  }

  Future<void> _fetchRoadRoute(LatLng origin, LatLng destination) async {
    final requestId = ++_routeRequestId;
    bool isCurrent() => mounted && requestId == _routeRequestId;
    try {
      final route = await widget.roadRoutingService.drivingRoute(
        origin: origin,
        destination: destination,
      );
      if (!isCurrent()) return;
      setState(() {
        _roadRoute = route;
        _routeError = null;
      });
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: route.points,
          padding: const EdgeInsets.fromLTRB(64, 108, 64, 320),
          maxZoom: 17,
        ),
      );
    } on RoadRoutingException catch (error) {
      if (isCurrent()) setState(() => _routeError = error.message);
    } catch (_) {
      if (isCurrent()) {
        setState(
          () => _routeError = 'Could not load road directions. Check your connection and try again.',
        );
      }
    } finally {
      if (isCurrent()) setState(() => _isGettingDirections = false);
    }
  }

  void _showDirectionsError(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: onRetry ?? _getDirections,
        ),
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

class _RouteStepsPanel extends StatelessWidget {
  const _RouteStepsPanel({
    required this.route,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final RoadRoute? route;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: route == null
          ? Center(
              child: error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error!, textAlign: TextAlign.center),
                        TextButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        const SizedBox(width: 10),
                        const Text('Finding a driving route…'),
                      ],
                    ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car_rounded, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Driving directions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${formatRouteDistance(route!.distanceMeters)} · ${formatRouteDuration(route!.durationSeconds)}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: route!.steps.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final step = route!.steps[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        title: Text(step.instruction),
                        trailing: Text(
                          formatRouteDistance(step.distanceMeters),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
    this.occupancyReport,
  });

  final ParkingLot lot;
  final bool isSaved;
  final VoidCallback onTap;
  final PermitEligibility permitEligibility;
  final OccupancyReport? occupancyReport;

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
                      occupancyReport == null
                          ? '${lot.spacesLabel} · ${lot.priceLabel}'
                          : '${occupancyReport!.status.label} · ${formatReportAge(occupancyReport!.reportedAt, DateTime.now())}',
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

class _AvailabilityLegend extends StatelessWidget {
  const _AvailabilityLegend();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text('Availability:', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 8),
          for (final status in ParkingAvailabilityStatus.values) ...[
            AvailabilityIndicator(status: status, compact: true),
            if (status != ParkingAvailabilityStatus.values.last)
              const SizedBox(width: 6),
          ],
        ],
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
