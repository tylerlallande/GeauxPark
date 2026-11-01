import 'package:flutter/material.dart';

import '../models/parking_details.dart';
import '../models/parking_lot.dart';
import '../repositories/parking_repository.dart';

typedef ParkingSaveCallback = Future<bool> Function(ParkingLot lot);

class ParkingDetailsScreen extends StatefulWidget {
  const ParkingDetailsScreen({
    super.key,
    required this.lot,
    required this.repository,
    required this.initiallySaved,
    this.onToggleSaved,
    this.onDirectionsRequested,
  });

  final ParkingLot lot;
  final ParkingRepository repository;
  final bool initiallySaved;
  final ParkingSaveCallback? onToggleSaved;
  final ValueChanged<ParkingDetails>? onDirectionsRequested;

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  late Future<ParkingDetails?> _detailsFuture;
  late bool _isSaved;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initiallySaved;
    _loadDetails();
  }

  void _loadDetails() {
    _detailsFuture = widget.repository.fetchParkingDetails(widget.lot.id);
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
            onDirectionsRequested: widget.onDirectionsRequested,
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
  });

  final ParkingLot lot;
  final ParkingDetails? details;
  final ValueChanged<ParkingDetails>? onDirectionsRequested;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, const Color(0xFF6C3AA0)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_parking_rounded, color: colors.secondary),
              const SizedBox(height: 28),
              Text(
                lot.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lot.address,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
              ),
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
                value: '${lot.distanceMiles.toStringAsFixed(1)} mi',
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
                value: '${lot.spacesAvailable}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
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
        ),
        _AmenitiesSection(amenities: details?.amenities ?? const []),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed:
              details != null &&
                  details!.hasCoordinates &&
                  onDirectionsRequested != null
              ? () => onDirectionsRequested!(details!)
              : null,
          icon: const Icon(Icons.directions_rounded),
          label: Text(
            details?.hasCoordinates == true
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
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String? content;

  @override
  Widget build(BuildContext context) {
    final value = content?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value == null || value.isEmpty
                ? 'Information not provided yet.'
                : value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
          Text(
            'Amenities',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
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
                      avatar: const Icon(Icons.check_rounded, size: 16),
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
