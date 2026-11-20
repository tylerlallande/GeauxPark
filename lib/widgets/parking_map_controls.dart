import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/parking_availability.dart';
import 'availability_indicator.dart';

class ParkingMapLocationButton extends StatelessWidget {
  const ParkingMapLocationButton({
    super.key,
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
    final strings = AppLocalizations.of(context);
    return Material(
      color: isTracking ? colors.primary : colors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: isTracking
            ? strings.stopLiveLocation
            : strings.useLiveLocation,
        onPressed: onPressed,
        color: isTracking ? colors.onPrimary : colors.primary,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isTracking ? Icons.location_searching : Icons.my_location),
      ),
    );
  }
}

class ParkingMapZoomControls extends StatelessWidget {
  const ParkingMapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    return Material(
      color: colors.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: strings.zoomIn,
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded),
          ),
          Container(height: 1, width: 40, color: colors.outlineVariant),
          IconButton(
            tooltip: strings.zoomOut,
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove_rounded),
          ),
        ],
      ),
    );
  }
}

class ParkingAvailabilityLegend extends StatelessWidget {
  const ParkingAvailabilityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            strings.availability,
            style: Theme.of(context).textTheme.labelMedium,
          ),
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

class ParkingPermitLegend extends StatelessWidget {
  const ParkingPermitLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 16, color: colors.tertiary),
        const SizedBox(width: 4),
        Text(strings.eligible),
        const SizedBox(width: 14),
        Icon(Icons.block_rounded, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(strings.permitRestricted),
      ],
    );
  }
}
