import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import '../models/parking_availability.dart';
import '../widgets/parking_lot_card.dart';
import '../theme/app_theme.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.lots,
    required this.savedLotIds,
    required this.isLoading,
    required this.loadFailed,
    required this.onRetry,
    required this.onToggleSaved,
    required this.onBrowseParking,
    required this.onLotSelected,
    required this.selectedPermits,
    this.occupancyReports = const {},
  });

  final List<ParkingLot> lots;
  final Set<String> savedLotIds;
  final bool isLoading;
  final bool loadFailed;
  final VoidCallback onRetry;
  final ValueChanged<ParkingLot>? onToggleSaved;
  final VoidCallback onBrowseParking;
  final ValueChanged<ParkingLot> onLotSelected;
  final Set<ParkingPermit> selectedPermits;
  final Map<String, OccupancyReport> occupancyReports;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final lots = this.lots
        .where((lot) => savedLotIds.contains(lot.id))
        .toList();

    if (loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.savedParkingLoadError),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ),
      );
    }
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return CustomScrollView(
      key: const PageStorageKey('saved-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.section,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          sliver: SliverList.list(
            children: [
              Text(
                strings.savedParking,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                strings.savedLocationCount(lots.length),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                    strings.noSavedParking,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.noSavedParkingHelp, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onBrowseParking,
                    child: Text(strings.findParking),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              28,
            ),
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
                  permitEligibility: lot.eligibilityFor(selectedPermits),
                  occupancyReport: occupancyReports[lot.id],
                );
              },
            ),
          ),
      ],
    );
  }
}
