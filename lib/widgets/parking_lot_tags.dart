import 'package:flutter/material.dart';

import '../models/parking_lot.dart';

class ParkingLotTags extends StatelessWidget {
  const ParkingLotTags({super.key, required this.lot});

  final ParkingLot lot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in ParkingTag.values.where(lot.tags.contains))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag.label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSecondaryContainer),
            ),
          ),
      ],
    );
  }
}
