import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/parking_lot.dart';
import '../models/parking_lot_layout.dart';
import '../repositories/parking_repository.dart';
import '../theme/app_theme.dart';

class ParkingLotLayoutScreen extends StatelessWidget {
  const ParkingLotLayoutScreen({
    super.key,
    required this.lot,
    required this.repository,
  });

  final ParkingLot lot;
  final ParkingLotLayoutRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.lotSpaces(lot.name))),
      body: FutureBuilder<ParkingLotLayout?>(
        future: repository.fetchParkingLotLayout(lot.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LayoutMessage(
              icon: Icons.cloud_off_outlined,
              title: strings.spaceMapUnavailable,
              message: strings.spaceMapLoadError,
            );
          }
          final layout = snapshot.data;
          if (layout == null || !layout.hasVerifiedSpaces) {
            return _LayoutMessage(
              icon: Icons.space_dashboard_outlined,
              title: strings.verifiedSpaceMapComingSoon,
              message: strings.verifiedSpaceMapPending,
            );
          }
          return _VerifiedLayout(layout: layout);
        },
      ),
    );
  }
}

class _VerifiedLayout extends StatelessWidget {
  const _VerifiedLayout({required this.layout});

  final ParkingLotLayout layout;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          strings.tapSpaceHelp,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.4,
          child: LayoutBuilder(
            builder: (context, constraints) => DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.panel),
              ),
              child: Stack(
                children: [
                  for (final space in layout.spaces)
                    Positioned(
                      left: space.x * constraints.maxWidth,
                      top: space.y * constraints.maxHeight,
                      width: space.width * constraints.maxWidth,
                      height: space.height * constraints.maxHeight,
                      child: Semantics(
                        button: true,
                        label:
                            '${space.label}, ${strings.parkingSpaceStatus(space.status)}',
                        child: Tooltip(
                          message:
                              '${space.label}: ${strings.parkingSpaceStatus(space.status)}',
                          child: Material(
                            color: _statusColor(context, space.status),
                            borderRadius: BorderRadius.circular(4),
                            child: InkWell(
                              onTap: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${space.label}: ${strings.parkingSpaceStatus(space.status)}',
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.source(layout.sourceLabel),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LayoutMessage extends StatelessWidget {
  const _LayoutMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(BuildContext context, ParkingSpaceStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    ParkingSpaceStatus.unknown => colors.outlineVariant,
    ParkingSpaceStatus.available => colors.tertiary,
    ParkingSpaceStatus.occupied => colors.error,
    ParkingSpaceStatus.unavailable => colors.onSurfaceVariant,
  };
}
