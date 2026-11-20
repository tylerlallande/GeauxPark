import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/parking_lot.dart';
import 'loading_skeleton.dart';

class ParkingDetailsLoading extends StatelessWidget {
  const ParkingDetailsLoading({super.key, required this.lot});

  final ParkingLot lot;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Semantics(
      label: strings.loadingDetails(lot.name),
      child: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(height: 190, borderRadius: 24),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: LoadingSkeleton(height: 92)),
                SizedBox(width: 12),
                Expanded(child: LoadingSkeleton(height: 92)),
              ],
            ),
            SizedBox(height: 16),
            LoadingSkeleton(height: 170, borderRadius: 20),
          ],
        ),
      ),
    );
  }
}

class ParkingDetailsError extends StatelessWidget {
  const ParkingDetailsError({
    super.key,
    required this.lot,
    required this.onRetry,
  });

  final ParkingLot lot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 16),
            Text(
              strings.couldNotLoad(lot.name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(strings.checkConnection, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ),
      ),
    );
  }
}
