import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('${lot.name} spaces')),
      body: FutureBuilder<ParkingLotLayout?>(
        future: repository.fetchParkingLotLayout(lot.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _LayoutMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Space map unavailable',
              message: 'Could not load this lot right now. Please try again.',
            );
          }
          final layout = snapshot.data;
          if (layout == null || !layout.hasVerifiedSpaces) {
            return const _LayoutMessage(
              icon: Icons.space_dashboard_outlined,
              title: 'Verified space map coming soon',
              message: 'This lot is ready for space-level data, but verified parking-space boundaries and live occupancy are not connected yet.',
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Tap a space to check its latest reported status.',
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
                        label: '${space.label}, ${_statusLabel(space.status)}',
                        child: Tooltip(
                          message:
                              '${space.label}: ${_statusLabel(space.status)}',
                          child: Material(
                            color: _statusColor(context, space.status),
                            borderRadius: BorderRadius.circular(4),
                            child: InkWell(
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${space.label}: ${_statusLabel(space.status)}',
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
          'Source: ${layout.sourceLabel}',
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

String _statusLabel(ParkingSpaceStatus status) => switch (status) {
  ParkingSpaceStatus.unknown => 'status unknown',
  ParkingSpaceStatus.available => 'available',
  ParkingSpaceStatus.occupied => 'occupied',
  ParkingSpaceStatus.unavailable => 'unavailable',
};

Color _statusColor(BuildContext context, ParkingSpaceStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    ParkingSpaceStatus.unknown => colors.outlineVariant,
    ParkingSpaceStatus.available => colors.tertiary,
    ParkingSpaceStatus.occupied => colors.error,
    ParkingSpaceStatus.unavailable => colors.onSurfaceVariant,
  };
}
