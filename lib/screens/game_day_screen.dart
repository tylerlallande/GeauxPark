import 'package:flutter/material.dart';

import '../models/game_day.dart';
import '../models/parking_lot.dart';
import '../theme/app_theme.dart';

class GameDayScreen extends StatelessWidget {
  const GameDayScreen({
    super.key,
    required this.plan,
    required this.lots,
    required this.onLotSelected,
  });

  final GameDayPlan plan;
  final List<ParkingLot> lots;
  final ValueChanged<ParkingLot> onLotSelected;

  @override
  Widget build(BuildContext context) {
    final lotsById = {for (final lot in lots) lot.id: lot};
    final statuses = plan.lotStatuses
        .where((status) => lotsById.containsKey(status.lotId))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Game day')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          32,
        ),
        children: [
          _GameDayHero(plan: plan),
          const SizedBox(height: AppSpacing.section),
          const _SectionTitle('Parking status'),
          const SizedBox(height: AppSpacing.md),
          if (statuses.isEmpty)
            const Text('Game-day parking status is not available yet.')
          else
            for (final status in statuses) ...[
              _GameDayLotTile(
                lot: lotsById[status.lotId]!,
                status: status,
                onTap: () => onLotSelected(lotsById[status.lotId]!),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: AppSpacing.md),
          const _SectionTitle('Game-day timeline'),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: Column(
                children: [
                  for (var i = 0; i < plan.timeline.length; i++)
                    _TimelineRow(
                      milestone: plan.timeline[i],
                      isLast: i == plan.timeline.length - 1,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          const _SectionTitle('Before you go'),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (var i = 0; i < plan.tips.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == plan.tips.length - 1 ? 0 : AppSpacing.md,
                      ),
                      child: _TipRow(text: plan.tips[i]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameDayHero extends StatelessWidget {
  const _GameDayHero({required this.plan});

  final GameDayPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadii.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sports_football_rounded,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              _HeroPill(
                icon: Icons.schedule_rounded,
                label: 'Lots open ${plan.lotsOpenLabel}',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            plan.title,
            style: text.headlineSmall?.copyWith(color: colors.onPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Kickoff ${plan.kickoffLabel} · ${plan.venue}',
            style: text.bodyLarge?.copyWith(color: AppColors.onPurpleMuted),
          ),
          if (plan.disclaimer != null) ...[
            const SizedBox(height: 10),
            Text(
              plan.disclaimer!,
              style: text.bodySmall?.copyWith(color: AppColors.onPurpleSubtle),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _GameDayLotTile extends StatelessWidget {
  const _GameDayLotTile({
    required this.lot,
    required this.status,
    required this.onTap,
  });

  final ParkingLot lot;
  final GameDayLotStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lot.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GameDayStatusTag(state: status.state),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(status.note, style: text.bodySmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _Fact(
                          icon: Icons.local_offer_outlined,
                          text: lot.priceLabel,
                        ),
                        _Fact(
                          icon: Icons.directions_walk_rounded,
                          text: '${lot.distanceMiles.toStringAsFixed(1)} mi',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small colored tag describing a lot's game-day state.
class GameDayStatusTag extends StatelessWidget {
  const GameDayStatusTag({super.key, required this.state});

  final GameDayLotState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (state) {
      GameDayLotState.open => (
        'OPEN',
        colors.tertiary.withValues(alpha: 0.1),
        colors.tertiary,
      ),
      GameDayLotState.fillingFast => (
        'FILLING FAST',
        colors.secondary.withValues(alpha: 0.35),
        colors.onSecondary,
      ),
      GameDayLotState.permitOnly => (
        'PERMIT ONLY',
        colors.primary.withValues(alpha: 0.1),
        colors.primary,
      ),
      GameDayLotState.full => (
        'FULL',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.tag),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.milestone, required this.isLast});

  final GameDayMilestone milestone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              milestone.timeLabel,
              style: text.labelLarge?.copyWith(color: colors.primary),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: colors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone.title, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(milestone.detail, style: text.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, size: 20, color: colors.tertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
