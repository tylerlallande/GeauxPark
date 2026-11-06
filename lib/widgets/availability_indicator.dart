import 'package:flutter/material.dart';

import '../models/parking_availability.dart';
import '../theme/app_theme.dart';

Color availabilityColor(ParkingAvailabilityStatus status, ColorScheme colors) =>
    switch (status) {
      ParkingAvailabilityStatus.unknown => colors.onSurfaceVariant,
      ParkingAvailabilityStatus.available => const Color(0xFF238636),
      ParkingAvailabilityStatus.fillingUp => const Color(0xFFF0A202),
      ParkingAvailabilityStatus.veryBusy => const Color(0xFFE66A21),
      ParkingAvailabilityStatus.full => colors.error,
    };

IconData availabilityIcon(ParkingAvailabilityStatus status) => switch (status) {
  ParkingAvailabilityStatus.unknown => Icons.help_outline_rounded,
  ParkingAvailabilityStatus.available => Icons.check_circle_outline_rounded,
  ParkingAvailabilityStatus.fillingUp => Icons.trending_up_rounded,
  ParkingAvailabilityStatus.veryBusy => Icons.warning_amber_rounded,
  ParkingAvailabilityStatus.full => Icons.block_rounded,
};

class AvailabilityIndicator extends StatelessWidget {
  const AvailabilityIndicator({
    super.key,
    required this.status,
    this.compact = false,
  });

  final ParkingAvailabilityStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = availabilityColor(status, Theme.of(context).colorScheme);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.tag),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(availabilityIcon(status), size: compact ? 14 : 17, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style:
                (compact
                        ? Theme.of(context).textTheme.labelSmall
                        : Theme.of(context).textTheme.labelMedium)
                    ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

Future<ParkingAvailabilityStatus?> showAvailabilityReportSheet(
  BuildContext context, {
  required String lotName,
  ParkingAvailabilityStatus? currentStatus,
}) => showModalBottomSheet<ParkingAvailabilityStatus>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How busy is $lotName?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose what you can observe right now. Reports are timestamped on this device.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          for (final status in ParkingAvailabilityStatus.values.where(
            (status) => status != ParkingAvailabilityStatus.unknown,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                key: ValueKey('report-availability-${status.id}'),
                onPressed: () => Navigator.pop(context, status),
                icon: Icon(availabilityIcon(status)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    status == currentStatus
                        ? '${status.label} (current report)'
                        : status.label,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);

String formatReportAge(DateTime reportedAt, DateTime now) {
  final age = now.difference(reportedAt.toLocal());
  if (age.isNegative || age.inMinutes < 1) return 'Reported just now';
  if (age.inMinutes < 60) return 'Reported ${age.inMinutes} min ago';
  if (age.inHours < 24) return 'Reported ${age.inHours} hr ago';
  return 'Reported ${age.inDays} days ago';
}
