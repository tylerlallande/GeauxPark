import 'package:flutter/material.dart';

import '../data/sample_parking_lots.dart';
import '../models/parking_lot.dart';
import '../widgets/parking_lot_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.savedLotIds,
    required this.isLoading,
    required this.loadFailed,
    required this.onRetry,
    required this.onToggleSaved,
    required this.onBrowseParking,
    required this.onLotSelected,
  });

  final Set<String> savedLotIds;
  final bool isLoading;
  final bool loadFailed;
  final VoidCallback onRetry;
  final ValueChanged<ParkingLot>? onToggleSaved;
  final VoidCallback onBrowseParking;
  final ValueChanged<ParkingLot> onLotSelected;

  @override
  Widget build(BuildContext context) {
    final lots = sampleParkingLots
        .where((lot) => savedLotIds.contains(lot.id))
        .toList();

    if (loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load saved parking.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return CustomScrollView(
      key: const PageStorageKey('saved-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: SliverList.list(
            children: [
              Text(
                'Saved parking',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${lots.length} saved ${lots.length == 1 ? 'location' : 'locations'}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        if (lots.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved parking yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the bookmark on a parking lot to keep it here.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onBrowseParking,
                    child: const Text('Find parking'),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: lots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lot = lots[index];
                return ParkingLotCard(
                  lot: lot,
                  isSaved: true,
                  onToggleSaved: onToggleSaved == null
                      ? null
                      : () => onToggleSaved!(lot),
                  onTap: () => onLotSelected(lot),
                );
              },
            ),
          ),
      ],
    );
  }
}
