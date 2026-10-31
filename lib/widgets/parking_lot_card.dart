import 'package:flutter/material.dart';

import '../models/parking_lot.dart';

class ParkingLotCard extends StatelessWidget {
  const ParkingLotCard({super.key, required this.lot, required this.onTap});

  final ParkingLot lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_parking_rounded,
                  color: colors.onPrimaryContainer,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lot.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _LotFact(
                          icon: Icons.directions_walk_rounded,
                          text: '${lot.distanceMiles.toStringAsFixed(1)} mi',
                        ),
                        _LotFact(
                          icon: Icons.local_offer_outlined,
                          text: lot.priceLabel,
                        ),
                        _LotFact(
                          icon: Icons.directions_car_filled_outlined,
                          text: '${lot.spacesAvailable} spots',
                          color: const Color(0xFF277A4A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotFact extends StatelessWidget {
  const _LotFact({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: resolvedColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: resolvedColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
