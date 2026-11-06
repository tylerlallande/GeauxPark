import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/parking_lot_tags.dart';

import '../models/parking_details.dart';
import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import '../models/parking_availability.dart';
import '../repositories/parking_repository.dart';
import '../services/directions_service.dart';
import '../theme/app_theme.dart';
import '../widgets/road_routing_consent.dart';
import '../widgets/availability_indicator.dart';

typedef ParkingSaveCallback = Future<bool> Function(ParkingLot lot);

class ParkingDetailsScreen extends StatefulWidget {
  const ParkingDetailsScreen({
    super.key,
    required this.lot,
    required this.repository,
    required this.initiallySaved,
    this.onToggleSaved,
    this.onDirectionsRequested,
    this.onOpenMapDirections,
    this.selectedPermits = const {},
    this.occupancyReport,
    this.onReportAvailability,
  });

  final ParkingLot lot;
  final ParkingRepository repository;
  final bool initiallySaved;
  final ParkingSaveCallback? onToggleSaved;
  final ValueChanged<ParkingDetails>? onDirectionsRequested;
  final ValueChanged<(ParkingDetails, LatLng)>? onOpenMapDirections;
  final Set<ParkingPermit> selectedPermits;
  final OccupancyReport? occupancyReport;
  final Future<bool> Function(ParkingLot lot, ParkingAvailabilityStatus status)?
  onReportAvailability;

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  late Future<ParkingDetails?> _detailsFuture;
  late bool _isSaved;
  bool _isSaving = false;
  final _directionsService = const DirectionsService();
  LatLng? _currentLocation;
  bool _isLocating = false;
  bool _isOpeningDirections = false;
  String? _locationMessage;
  OccupancyReport? _occupancyReport;
  bool _isReportingAvailability = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
    _occupancyReport = widget.occupancyReport;
    _loadDetails();
  }

  @override
  void didUpdateWidget(covariant ParkingDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.occupancyReport != oldWidget.occupancyReport) {
      _occupancyReport = widget.occupancyReport;
    }
  }

  void _loadDetails() {
    _detailsFuture = widget.repository.fetchParkingDetails(widget.lot.id);
  }

  Future<LatLng?> _getCurrentLocation() async {
    if (_currentLocation != null) return _currentLocation;
    if (_isLocating) return null;
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });
    try {
      final location = await _directionsService.currentLocation();
      if (!mounted) return location;
      setState(() => _currentLocation = location);
      return location;
    } on DirectionsException catch (error) {
      if (mounted) setState(() => _locationMessage = error.message);
      return null;
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationMessage =
              'Could not get your location. Please try again.',
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openDirections(ParkingDetails details) async {
    if (!details.hasCoordinates || _isOpeningDirections) return;
    final origin = await _getCurrentLocation();
    if (!mounted || origin == null) return;
    final openMap = widget.onOpenMapDirections;
    if (openMap != null) {
      if (!await confirmRoadRoutingConsent(context) || !mounted) return;
      openMap((details, origin));
      return;
    }
    final mode = await showModalBottomSheet<DirectionsMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Directions to ${widget.lot.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, DirectionsMode.driving),
                icon: const Icon(Icons.directions_car_rounded),
                label: const Text('Drive'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, DirectionsMode.walking),
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Walk'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || mode == null) return;
    setState(() => _isOpeningDirections = true);
    try {
      final opened = await _directionsService.openDirections(
        origin: origin,
        destination: LatLng(details.latitude!, details.longitude!),
        mode: mode,
      );
      if (mounted && !opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps. Please try again.'),
          ),
        );
      }
    } on DirectionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isOpeningDirections = false);
    }
  }

  Future<void> _toggleSaved() async {
    final callback = widget.onToggleSaved;
    if (callback == null || _isSaving) return;
    setState(() => _isSaving = true);
    final succeeded = await callback(widget.lot);
    if (!mounted) return;
    setState(() {
      if (succeeded) _isSaved = !_isSaved;
      _isSaving = false;
    });
  }

  Future<void> _reportAvailability() async {
    final callback = widget.onReportAvailability;
    if (callback == null || _isReportingAvailability) return;
    final status = await showAvailabilityReportSheet(
      context,
      lotName: widget.lot.name,
      currentStatus: _occupancyReport?.status,
    );
    if (!mounted || status == null) return;
    setState(() => _isReportingAvailability = true);
    final succeeded = await callback(widget.lot, status);
    if (!mounted) return;
    setState(() {
      if (succeeded) {
        _occupancyReport = OccupancyReport(
          lotId: widget.lot.id,
          status: status,
          reportedAt: DateTime.now(),
        );
      }
      _isReportingAvailability = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking details'),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Remove from saved' : 'Save parking',
            onPressed: widget.onToggleSaved == null ? null : _toggleSaved,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
          ),
        ],
      ),
      body: FutureBuilder<ParkingDetails?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _DetailsLoading(lot: widget.lot);
          }
          if (snapshot.hasError) {
            return _DetailsError(
              lot: widget.lot,
              onRetry: () => setState(_loadDetails),
            );
          }
          return _DetailsContent(
            lot: widget.lot,
            details: snapshot.data,
            onDirectionsRequested:
                widget.onDirectionsRequested ?? _openDirections,
            selectedPermits: widget.selectedPermits,
            currentLocation: _currentLocation,
            isLocating: _isLocating,
            isOpeningDirections: _isOpeningDirections,
            locationMessage: _locationMessage,
            onRequestLocation: _getCurrentLocation,
            occupancyReport: _occupancyReport,
            isReportingAvailability: _isReportingAvailability,
            onReportAvailability: widget.onReportAvailability == null
                ? null
                : _reportAvailability,
          );
        },
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.lot,
    required this.details,
    required this.onDirectionsRequested,
    required this.selectedPermits,
    required this.currentLocation,
    required this.isLocating,
    required this.isOpeningDirections,
    required this.locationMessage,
    required this.onRequestLocation,
    required this.occupancyReport,
    required this.isReportingAvailability,
    required this.onReportAvailability,
  });

  final ParkingLot lot;
  final ParkingDetails? details;
  final ValueChanged<ParkingDetails>? onDirectionsRequested;
  final Set<ParkingPermit> selectedPermits;
  final LatLng? currentLocation;
  final bool isLocating;
  final bool isOpeningDirections;
  final String? locationMessage;
  final Future<LatLng?> Function() onRequestLocation;
  final OccupancyReport? occupancyReport;
  final bool isReportingAvailability;
  final VoidCallback? onReportAvailability;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final availabilityStatus =
        occupancyReport?.status ?? lot.availabilityStatus;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppRadii.panel),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.local_parking_rounded,
                      color: colors.onSecondary,
                    ),
                  ),
                  const Spacer(),
                  AvailabilityIndicator(status: availabilityStatus),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                lot.name,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: colors.onPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                lot.address,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.onPurpleMuted),
              ),
              if (details?.availabilityUpdatedAt != null) ...[
                const SizedBox(height: 10),
                _FreshnessLabel(updatedAt: details!.availabilityUpdatedAt!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.directions_walk_rounded,
                label: 'Distance',
                value:
                    currentLocation != null && details?.hasCoordinates == true
                    ? _distanceLabel(
                        currentLocation!,
                        LatLng(details!.latitude!, details!.longitude!),
                      )
                    : isLocating
                    ? 'Finding you…'
                    : locationMessage != null
                    ? 'Unavailable'
                    : lot.distanceLabel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.local_offer_outlined,
                label: 'Price',
                value: lot.priceLabel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.directions_car_filled_outlined,
                label: 'Available',
                value:
                    occupancyReport?.status.label ??
                    lot.spacesAvailable?.toString() ??
                    'Unknown',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: availabilityStatus == ParkingAvailabilityStatus.unknown
              ? 'Parking availability is not reported'
              : 'Parking availability reported as ${availabilityStatus.label}',
          child: Text(
            occupancyReport != null
                ? '${formatReportAge(occupancyReport!.reportedAt, DateTime.now())}. Community reports can change quickly.'
                : lot.spacesAvailable == null
                ? 'Live availability is not provided for this lot.'
                : lot.isAvailable
                ? 'Availability can change quickly on event days.'
                : 'Check back soon or explore another nearby lot.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        if (locationMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            locationMessage!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isLocating ? null : onRequestLocation,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Try location again'),
            ),
          ),
        ],
        const SizedBox(height: 22),
        OutlinedButton.icon(
          key: const ValueKey('details-report-availability'),
          onPressed: isReportingAvailability ? null : onReportAvailability,
          icon: isReportingAvailability
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.campaign_outlined),
          label: Text(
            isReportingAvailability ? 'Saving report…' : 'Report availability',
          ),
        ),
        const SizedBox(height: 12),
        _PermitAccessCard(lot: lot, selectedPermits: selectedPermits),
        const SizedBox(height: 12),
        ParkingLotTags(lot: lot),
        const SizedBox(height: 16),
        _DetailsPanel(
          children: [
            _DetailSection(
              title: 'About this location',
              icon: Icons.info_outline_rounded,
              content: details?.description,
            ),
            _DetailSection(
              title: 'Hours',
              icon: Icons.schedule_rounded,
              content: details?.hours,
            ),
            _DetailSection(
              title: 'Game-day information',
              icon: Icons.sports_football_rounded,
              content: details?.eventRestrictions,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AmenitiesSection(amenities: details?.amenities ?? const []),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: isOpeningDirections || isLocating
              ? null
              : details != null &&
                    details!.hasCoordinates &&
                    onDirectionsRequested != null
              ? () => onDirectionsRequested!(details!)
              : null,
          icon: isOpeningDirections || isLocating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.directions_rounded),
          label: Text(
            isLocating
                ? 'Getting your location…'
                : details?.hasCoordinates == true
                ? 'Get directions'
                : 'Directions unavailable',
          ),
        ),
        if (details == null) ...[
          const SizedBox(height: 12),
          Text(
            'Additional information will appear when a parking data provider is connected.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

String _distanceLabel(LatLng origin, LatLng destination) {
  final miles = const Distance().as(LengthUnit.Mile, origin, destination);
  if (miles < 0.1) return '${(miles * 5280).round()} ft';
  return '${miles.toStringAsFixed(1)} mi';
}

class _PermitAccessCard extends StatelessWidget {
  const _PermitAccessCard({required this.lot, required this.selectedPermits});

  final ParkingLot lot;
  final Set<ParkingPermit> selectedPermits;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final eligibility = lot.eligibilityFor(selectedPermits);
    final isEligible = eligibility == PermitEligibility.eligible;
    final isConfigured = eligibility != PermitEligibility.notConfigured;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: !isConfigured
            ? colors.surfaceContainerHighest
            : isEligible
            ? colors.tertiary.withValues(alpha: 0.1)
            : colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                !isConfigured
                    ? Icons.badge_outlined
                    : isEligible
                    ? Icons.verified_outlined
                    : Icons.block_rounded,
                color: !isConfigured
                    ? colors.onSurfaceVariant
                    : isEligible
                    ? colors.tertiary
                    : colors.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  !isConfigured
                      ? 'Add a permit to check access'
                      : isEligible
                      ? 'Works with your permit'
                      : 'Your permit is not accepted here',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Accepted: ${lot.permitTypes.map((permit) => permit.label).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FreshnessLabel extends StatelessWidget {
  const _FreshnessLabel({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.sync_rounded,
          size: 14,
          color: AppColors.onPurpleSubtle,
        ),
        const SizedBox(width: 5),
        Text(
          'Updated ${_formatTime(updatedAt)}',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.onPurpleSubtle),
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
        child: Column(children: children),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.content,
    this.isLast = false,
  });

  final String title;
  final IconData icon;
  final String? content;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = content?.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value == null || value.isEmpty
                ? 'Information not provided yet.'
                : value,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesSection extends StatelessWidget {
  const _AmenitiesSection({required this.amenities});

  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (amenities.isEmpty)
            const Text('Information not provided yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities
                  .map(
                    (amenity) => Chip(
                      avatar: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(amenity),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _DetailsLoading extends StatelessWidget {
  const _DetailsLoading({required this.lot});

  final ParkingLot lot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading details for ${lot.name}',
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.lot, required this.onRetry});

  final ParkingLot lot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 16),
            Text(
              'Could not load ${lot.name}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
